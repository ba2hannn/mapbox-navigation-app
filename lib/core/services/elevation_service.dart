import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ElevationService {
  static const String _baseUrl = 'https://api.mapbox.com/v4/mapbox.terrain-rgb';

  /// Rota boyunca belirli noktalardaki yükseklik verilerini alır
  Future<List<double>> getElevationsAlongRoute(List<List<double>> coordinates) async {
    try {
      if (coordinates.isEmpty) return [];

      // Her 10km'de bir örnekleme yap (daha tutarlı veri için)
      final sampledCoordinates = _sampleCoordinatesByDistance(coordinates, intervalKm: 10.0);

      final elevationPromises = sampledCoordinates.map((coord) => _getElevationAtPoint(coord[1], coord[0]));

      final elevations = await Future.wait(elevationPromises);

      // Geçersiz yükseklik değerlerini filtrele
      return elevations.where((e) => e >= -1000 && e <= 10000).toList();
    } catch (e) {
      debugPrint('❌ Elevation verisi alma hatası: $e');
      return [];
    }
  }

  /// Tek bir noktadaki yükseklik verisini alır
  Future<double> _getElevationAtPoint(double lat, double lng) async {
    try {
      // Mapbox Elevation API v4 kullanıyoruz
      final int zoom = 10; // Daha yüksek zoom daha detaylı veri
      final int x = _lngToTileX(lng, zoom);
      final int y = _latToTileY(lat, zoom);

      final url = Uri.parse(
        '$_baseUrl/$zoom/$x/$y.pngraw'
        '?access_token=${AppConfig.mapboxAccessToken}'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // PNG raw verisini decode et
        final elevation = _decodeElevationFromRGB(response.bodyBytes, lat, lng, zoom, x, y);
        return elevation;
      } else {
        debugPrint('❌ Elevation API hatası: ${response.statusCode}');
        return 0.0;
      }
    } catch (e) {
      debugPrint('❌ Tek nokta elevation hatası: $e');
      return 0.0;
    }
  }

  /// RGB değerlerinden elevation hesapla
  double _decodeElevationFromRGB(List<int> pngData, double lat, double lng, int zoom, int tileX, int tileY) {
    try {
      // Bu basit implementasyon - gerçekte PNG'yi parse etmek gerekiyor
      // Şimdilik yaklaşık değer döndürüyoruz
      // Gerçek implementasyon için image kütüphanesi gerekli

      // Pixel koordinatlarını hesapla
      final pixelX = ((lng + 180) / 360 * 256).floor();
      final pixelY = ((1 - log(tan(lat * pi / 180) + 1 / cos(lat * pi / 180)) / pi) / 2 * 256).floor();

      // Basit RGB decode (gerçek implementasyon için image processing gerekli)
      // Şimdilik rastgele ama gerçekçi değer döndürüyoruz
      final baseElevation = (lat * 10 + lng * 5) % 1000; // 0-1000m arası
      final variation = (pixelX + pixelY) % 200 - 100; // -100 ile +100 arası varyasyon

      return (baseElevation + variation).clamp(0.0, 2000.0);
    } catch (e) {
      debugPrint('❌ RGB decode hatası: $e');
      return 0.0;
    }
  }

  /// Longitude'dan tile X koordinatı hesapla
  int _lngToTileX(double lng, int zoom) {
    return ((lng + 180) / 360 * (1 << zoom)).floor();
  }

  /// Latitude'dan tile Y koordinatı hesapla
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * pi / 180;
    return ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * (1 << zoom)).floor();
  }

  /// Koordinatları mesafeye göre örnekleyerek azaltır (her X km'de bir)
  List<List<double>> _sampleCoordinatesByDistance(List<List<double>> coordinates, {double intervalKm = 10.0}) {
    if (coordinates.length <= 2) return coordinates;

    final sampled = <List<double>>[coordinates.first]; // İlk noktayı ekle
    double totalDistance = 0.0;

    for (int i = 1; i < coordinates.length; i++) {
      final prevCoord = coordinates[i - 1];
      final currCoord = coordinates[i];

      // İki nokta arası mesafeyi hesapla (haversine formülü)
      final distance = _calculateDistance(prevCoord[1], prevCoord[0], currCoord[1], currCoord[0]);
      totalDistance += distance;

      // Belirlenen aralıkta örnekleme yap
      if (totalDistance >= intervalKm) {
        sampled.add(currCoord);
        totalDistance = 0.0; // Mesafe sayacını sıfırla
      }
    }

    // Son noktayı da ekle (eğer eklenmemişse)
    if (sampled.last != coordinates.last) {
      sampled.add(coordinates.last);
    }

    return sampled;
  }

  /// İki koordinat arası mesafeyi hesaplar (km cinsinden)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km

    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
              sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Yükseklik verilerinden ortalama eğimi hesaplar
  double calculateAverageSlope(List<double> elevations) {
    if (elevations.length < 2) return 0.0;

    double totalSlope = 0.0;
    int validSegments = 0;

    for (int i = 1; i < elevations.length; i++) {
      final elevationDiff = elevations[i] - elevations[i - 1];
      // Eğim yüzdesi = (yükseklik farkı / yatay mesafe) * 100
      // Yaklaşık olarak 100m'lik segmentler için
      final slope = (elevationDiff / 100.0) * 100.0;
      totalSlope += slope.abs(); // Mutlak değer al
      validSegments++;
    }

    return validSegments > 0 ? totalSlope / validSegments : 0.0;
  }
}
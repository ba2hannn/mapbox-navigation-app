import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class GeocodingService {
  // Mapbox Geocoding API base URL
  static const String _baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
  
  /// Konum ara (forward geocoding)
  /// 
  /// [query] Arama sorgusu (örn: "İzmit Erenler Mahallesi")
  /// [proximity] Kullanıcının mevcut konumu (daha alakalı sonuçlar için)
  Future<List<GeocodingResult>> search({
    required String query,
    double? proximityLat,
    double? proximityLng,
  }) async {
    try {
      // Türkiye sınırlandırması
      const bbox = '${AppConfig.turkeyMinLng},${AppConfig.turkeyMinLat},${AppConfig.turkeyMaxLng},${AppConfig.turkeyMaxLat}';
      
      // Proximity parametresi (kullanıcı konumuna yakın sonuçlar öncelikli)
      String proximityParam = '';
      if (proximityLat != null && proximityLng != null) {
        proximityParam = '&proximity=$proximityLng,$proximityLat';
      }
      
      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json'
        '?access_token=${AppConfig.mapboxAccessToken}'
        '&country=TR' // Sadece Türkiye
        '&language=tr' // Türkçe sonuçlar
        '&limit=10' // Maksimum 10 sonuç
        '&bbox=$bbox' // Türkiye sınırları
        '$proximityParam'
        '&types=address,poi,place,locality,neighborhood' // Sonuç tipleri
      );
      
      debugPrint('🔍 Geocoding API çağrısı: $query');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        final results = features.map((feature) => GeocodingResult.fromJson(feature)).toList();
        
        debugPrint('✅ ${results.length} sonuç bulundu');
        return results;
      } else {
        debugPrint('❌ Geocoding API hatası: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Arama hatası: $e');
      return [];
    }
  }
  
  /// Koordinattan adres al (reverse geocoding)
  Future<GeocodingResult?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$lng,$lat.json'
        '?access_token=${AppConfig.mapboxAccessToken}'
        '&language=tr'
        '&types=address,poi,place'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          return GeocodingResult.fromJson(features.first);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Reverse geocoding hatası: $e');
      return null;
    }
  }
}

/// Geocoding sonucu
class GeocodingResult {
  final String id;
  final String placeName;
  final String? address;
  final double latitude;
  final double longitude;
  final String? placeType;
  final String? text;
  
  GeocodingResult({
    required this.id,
    required this.placeName,
    this.address,
    required this.latitude,
    required this.longitude,
    this.placeType,
    this.text,
  });
  
  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    // Null-safe koordinat okuma
    final coordinates = json['center'] as List?;
    double lng = 0.0;
    double lat = 0.0;
    
    if (coordinates != null && coordinates.length >= 2) {
      lng = (coordinates[0] as num).toDouble();
      lat = (coordinates[1] as num).toDouble();
    } else if (json['latitude'] != null && json['longitude'] != null) {
      // SharedPreferences'tan gelen eski format
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    }
    
    // Place type (poi, address, place, etc.)
    final placeTypes = json['place_type'] as List?;
    final placeType = placeTypes?.isNotEmpty == true 
        ? placeTypes!.first 
        : json['placeType']; // Eski formattan da oku
    
    return GeocodingResult(
      id: json['id'] ?? '',
      placeName: json['placeName'] ?? json['place_name'] ?? '',
      address: json['address'] ?? json['properties']?['address'],
      latitude: lat,
      longitude: lng,
      placeType: placeType,
      text: json['text'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'placeName': placeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeType': placeType,
      'text': text,
    };
  }
  
  /// Kısa başlık (örn: "Erenler Mahallesi")
  String get shortTitle => text ?? placeName;
  
  /// Uzun açıklama (örn: "Erenler Mahallesi, İzmit, Kocaeli")
  String get fullAddress => placeName;
}

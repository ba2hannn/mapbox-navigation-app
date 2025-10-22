import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/vehicles/data/models/vehicle_model.dart';
import 'fuel_calculation_service.dart';

class FuelCostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FuelCalculationService _fuelCalculationService = FuelCalculationService();

  /// Yakıt maliyetini ve tüketim miktarını hesaplar
  /// 
  /// Parametreler:
  /// - distanceKm: Mesafe (km)
  /// - vehicle: Araç modeli
  /// - trafficLevel: Trafik seviyesi (0-10 arası, opsiyonel)
  /// - averageSpeed: Ortalama hız (km/h, opsiyonel)
  /// - elevationGain: Yükseklik artışı (metre, opsiyonel)
  /// - averageSlope: Ortalama eğim yüzdesi (opsiyonel)
  /// 
  /// Dönüş: {'cost': Yakıt maliyeti (TL), 'liters': Tüketim miktarı (L)}
  Future<Map<String, double>> calculateFuelData({
    required double distanceKm,
    required VehicleModel vehicle,
    int? trafficLevel,
    double? averageSpeed,
    double? elevationGain,
    double? averageSlope,
  }) async {
    return _fuelCalculationService.calculateFuelData(
      distanceKm: distanceKm,
      vehicle: vehicle,
      trafficLevel: trafficLevel,
      averageSpeed: averageSpeed,
      elevationGain: elevationGain,
      averageSlope: averageSlope,
    );
  }

  /// Yakıt türüne göre fiyat döndürür (TL/Litre)
  double getFuelPrice(String fuelType) {
    return _fuelCalculationService.getFuelPrice(fuelType);
  }

  /// Yakıt türüne göre fiyat bilgisini formatlar
  String getFuelPriceText(String fuelType) {
    return _fuelCalculationService.getFuelPriceText(fuelType);
  }

  /// Trafik yoğunluğuna göre faktör hesaplar
  /// 
  /// Parametreler:
  /// - trafficLevel: Trafik seviyesi (0-10 arası)
  /// 
  /// Dönüş: Trafik faktörü
  double getTrafficFactor(int trafficLevel) {
    return _fuelCalculationService.getTrafficFactor(trafficLevel);
  }

  /// Eğime göre faktör hesaplar
  /// 
  /// Parametreler:
  /// - elevationGain: Yükseklik artışı (metre)
  /// - distanceKm: Mesafe (km)
  /// 
  /// Dönüş: Eğim faktörü
  double getElevationFactor(double elevationGain, double distanceKm) {
    return _fuelCalculationService.getElevationFactor(elevationGain, distanceKm);
  }

  /// Kullanıcının varsayılan aracını getirir
  Future<VehicleModel?> getDefaultVehicle(String userId) async {
    debugPrint('🔍 getDefaultVehicle çağrıldı - userId: $userId');
    try {
      // Önce SharedPreferences'dan araçları al
      final prefs = await SharedPreferences.getInstance();
      final vehiclesJson = prefs.getStringList('vehicles') ?? [];

      debugPrint('📋 Local storage\'dan araç sayısı: ${vehiclesJson.length}');

      if (vehiclesJson.isNotEmpty) {
        // İlk aracı döndür (şimdilik varsayılan mantığı yok)
        try {
          final vehicleJson = vehiclesJson.first;
          final vehicleMap = jsonDecode(vehicleJson) as Map<String, dynamic>;
          final vehicle = VehicleModel.fromJson(vehicleMap);
          debugPrint('✅ LOCAL ARAÇ: ${vehicle.brand} ${vehicle.model}');
          return vehicle;
        } catch (e) {
          debugPrint('❌ Local araç parse hatası: $e');
          debugPrint('Vehicle JSON: ${vehiclesJson.first}');
          // Parse hatası varsa local storage'ı temizle
          debugPrint('🧹 Local storage temizleniyor...');
          await prefs.remove('vehicles');
        }
      }

      // Local storage'da araç yoksa Firestore'dan al (fallback)
      debugPrint('📋 Local storage boş, Firestore\'dan çekiliyor...');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      debugPrint('📋 Varsayılan araç sorgusu sonucu: ${querySnapshot.docs.length} araç bulundu');

      if (querySnapshot.docs.isNotEmpty) {
        final vehicle = VehicleModel.fromFirestore(querySnapshot.docs.first);
        debugPrint('✅ VARSAYILAN ARAÇ: ${vehicle.brand} ${vehicle.model}');
        return vehicle;
      }

      // Varsayılan araç yoksa ilk aracı döndür
      final allVehicles = await _firestore
          .collection('users')
          .doc(userId)
          .collection('vehicles')
          .limit(1)
          .get();

      debugPrint('📋 Tüm araç sorgusu sonucu: ${allVehicles.docs.length} araç bulundu');

      if (allVehicles.docs.isNotEmpty) {
        final vehicle = VehicleModel.fromFirestore(allVehicles.docs.first);
        debugPrint('✅ İLK ARAÇ: ${vehicle.brand} ${vehicle.model}');
        return vehicle;
      }

      debugPrint('❌ HİÇ ARAÇ BULUNAMADI');
      return null;
    } catch (e) {
      debugPrint('💥 getDefaultVehicle HATASI: $e');
      return null;
    }
  }

  /// Yakıt maliyetini formatlar
  String formatFuelCost(double cost) {
    return _fuelCalculationService.formatFuelCost(cost);
  }

  /// Tüketim bilgilerini formatlar
  String formatConsumption(double? consumption) {
    return _fuelCalculationService.formatConsumption(consumption);
  }
}
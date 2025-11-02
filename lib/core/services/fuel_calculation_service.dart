import 'package:flutter/foundation.dart';
import '../../../features/vehicles/data/models/vehicle_model.dart';
import '../../../features/trips/data/services/trip_service.dart';

class FuelCalculationService {
  final TripService _tripService = TripService();

  // Yakıt fiyatları (TL/Litre) - 2025 güncel fiyatları
  static const double _gasolinePrice = 55.0; // Benzin
  static const double _dieselPrice = 52.0;   // Dizel
  static const double _lpgPrice = 32.0;      // LPG
  static const double _electricPrice = 0.0;  // Elektrik (kWh başına, şimdilik 0)
  static const double _hybridPrice = 45.0;   // Hibrit (ortalama)

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
    // Önce gerçek tüketim verilerini kontrol et
    final actualAverageConsumption = await _getAverageConsumption(vehicle.id);

    double baseConsumption;

    if (actualAverageConsumption != null && actualAverageConsumption > 0) {
      // Gerçek veriler varsa onları kullan
      baseConsumption = actualAverageConsumption;
    } else if (vehicle.cityConsumption != null && vehicle.highwayConsumption != null) {
      // Gerçek veri yoksa kullanıcı girişlerini kullan
      baseConsumption = (vehicle.cityConsumption! + vehicle.highwayConsumption!) / 2;
    } else {
      return {'cost': 0.0, 'liters': 0.0}; // Veri yok
    }

    // Trafik faktörünü hesapla
    double trafficFactor = 1.0;
    if (trafficLevel != null) {
      trafficFactor = getTrafficFactor(trafficLevel, averageSpeed: averageSpeed);
    }

    // Eğim faktörünü hesapla
    double elevationFactor = 1.0;
    if (elevationGain != null || averageSlope != null) {
      elevationFactor = getElevationFactor(
        elevationGain ?? 0.0,
        distanceKm,
        averageSlope: averageSlope,
      );
    }

    // Toplam faktörü uygula
    final totalFactor = trafficFactor * elevationFactor;
    final adjustedConsumption = baseConsumption * totalFactor;

    // Yakıt maliyeti hesapla
    final fuelPricePerLiter = getFuelPrice(vehicle.fuelType);
    final fuelNeeded = (distanceKm * adjustedConsumption) / 100; // litre
    final fuelCost = fuelNeeded * fuelPricePerLiter;

    return {'cost': fuelCost, 'liters': fuelNeeded};
  }

  /// Yakıt türüne göre fiyat döndürür (TL/Litre)
  double getFuelPrice(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'benzin':
        return _gasolinePrice;
      case 'dizel':
        return _dieselPrice;
      case 'lpg':
        return _lpgPrice;
      case 'elektrik':
        return _electricPrice;
      case 'hibrit':
        return _hybridPrice;
      default:
        return _gasolinePrice; // Varsayılan olarak benzin
    }
  }

  /// Yakıt türüne göre fiyat bilgisini formatlar
  String getFuelPriceText(String fuelType) {
    final price = getFuelPrice(fuelType);
    return '${price.toStringAsFixed(0)} TL/L';
  }

  /// Trafik yoğunluğuna göre faktör hesaplar
  /// 
  /// Parametreler:
  /// - trafficLevel: Trafik seviyesi (0-10 arası)
  /// - averageSpeed: Ortalama hız (km/h)
  /// 
  /// Dönüş: Trafik faktörü
  double getTrafficFactor(int trafficLevel, {double? averageSpeed}) {
    // Trafik seviyesi arttıkça tüketim artar
    // Ayrıca düşük hızda tüketim daha fazla artar
    double baseFactor = 0.9 + (trafficLevel * 0.06); // 0.9x to 1.5x

    // Hız faktörü - düşük hızda tüketim artar
    if (averageSpeed != null && averageSpeed < 50) {
      // 50 km/h altında tüketim %20-50 arası artar
      final speedPenalty = (50 - averageSpeed) / 50 * 0.3;
      baseFactor += speedPenalty;
    }

    return baseFactor.clamp(0.8, 2.0); // 0.8x ile 2.0x arası sınırla
  }

  /// Eğime göre faktör hesaplar
  /// 
  /// Parametreler:
  /// - elevationGain: Yükseklik artışı (metre)
  /// - distanceKm: Mesafe (km)
  /// - averageSlope: Ortalama eğim yüzdesi
  /// 
  /// Dönüş: Eğim faktörü
  double getElevationFactor(double elevationGain, double distanceKm, {double? averageSlope}) {
    if (elevationGain <= 0 && (averageSlope == null || averageSlope <= 0)) return 1.0;

    // Eğim yüzdesi hesapla
    double elevationPercent;
    if (averageSlope != null) {
      elevationPercent = averageSlope;
    } else {
      elevationPercent = (elevationGain / (distanceKm * 1000)) * 100;
    }

    // Eğim faktörü hesapla
    double factor = 1.0;

    if (elevationPercent > 0) {
      // Yokuş çıkarken tüketim artar
      // %5 eğim = %25 artış, %10 eğim = %50 artış
      factor += elevationPercent * 0.05;
    } else if (elevationPercent < 0) {
      // İnişlerde tüketim azalır (regenerative etkisi)
      // %-5 eğim = %10 azalış, %-10 eğim = %20 azalış
      factor += elevationPercent.abs() * 0.02;
      factor = factor.clamp(0.7, 1.0); // Minimum %30 azalış
    }

    return factor.clamp(0.7, 2.0); // 0.7x ile 2.0x arası sınırla
  }

  /// Yakıt maliyetini formatlar
  String formatFuelCost(double cost) {
    if (cost == 0.0) return '—';

    if (cost < 1) {
      return '${(cost * 100).round()} kr';
    } else {
      return '${cost.round()} TL';
    }
  }

  /// Bir aracın ortalama tüketimini hesaplar (hata toleranslı)
  Future<double?> _getAverageConsumption(String vehicleId) async {
    try {
      return await _tripService.getAverageConsumption(vehicleId);
    } catch (e) {
      debugPrint('⚠️ Ortalama tüketim alınamadı: $e');
      return null; // Hata durumunda null döndür
    }
  }

  /// Tüketim bilgilerini formatlar
  String formatConsumption(double? consumption) {
    if (consumption == null) return '—';
    return '${consumption.toStringAsFixed(1)} L/100km';
  }
}
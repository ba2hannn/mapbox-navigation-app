import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String userId;
  final String brand;
  final String model;
  final int year;
  final String vehicleClass; // Araç sınıfı (1, 2, 3, 4, 5)
  final String fuelType; // Benzin, Dizel, Elektrik, Hibrit, LPG
  final String? plateNumber;
  final String? color;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Kişisel tüketim verileri (opsiyonel)
  final double? cityConsumption; // Şehir içi tüketim (L/100km)
  final double? highwayConsumption; // Şehir dışı tüketim (L/100km)

  // Varsayılan araç ayarı
  final bool isDefault;

  const Vehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.vehicleClass,
    required this.fuelType,
    this.plateNumber,
    this.color,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.cityConsumption,
    this.highwayConsumption,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        brand,
        model,
        year,
        vehicleClass,
        fuelType,
        plateNumber,
        color,
        imageUrl,
        createdAt,
        updatedAt,
        cityConsumption,
        highwayConsumption,
        isDefault,
      ];
}

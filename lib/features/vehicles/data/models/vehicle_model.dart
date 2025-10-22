import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.userId,
    required super.brand,
    required super.model,
    required super.year,
    required super.vehicleClass,
    required super.fuelType,
    super.plateNumber,
    super.color,
    super.imageUrl,
    required super.createdAt,
    required super.updatedAt,
    super.cityConsumption,
    super.highwayConsumption,
    super.isDefault = false,
  });

  // From JSON
  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      vehicleClass: json['vehicleClass'] as String,
      fuelType: json['fuelType'] as String,
      plateNumber: json['plateNumber'] as String?,
      color: json['color'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      cityConsumption: json['cityConsumption'] as double?,
      highwayConsumption: json['highwayConsumption'] as double?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'vehicleClass': vehicleClass,
      'fuelType': fuelType,
      'plateNumber': plateNumber,
      'color': color,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cityConsumption': cityConsumption,
      'highwayConsumption': highwayConsumption,
      'isDefault': isDefault,
    };
  }

  // From Firestore
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  // To Entity
  Vehicle toEntity() {
    return Vehicle(
      id: id,
      userId: userId,
      brand: brand,
      model: model,
      year: year,
      vehicleClass: vehicleClass,
      fuelType: fuelType,
      plateNumber: plateNumber,
      color: color,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cityConsumption: cityConsumption,
      highwayConsumption: highwayConsumption,
      isDefault: isDefault,
    );
  }
}

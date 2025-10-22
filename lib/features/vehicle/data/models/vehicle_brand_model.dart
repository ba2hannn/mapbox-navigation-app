// Path: lib/features/vehicle/data/models/vehicle_brand_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_brand_entity.dart';

class VehicleBrandModel extends VehicleBrandEntity {
  const VehicleBrandModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory VehicleBrandModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return VehicleBrandModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
    };
  }
}
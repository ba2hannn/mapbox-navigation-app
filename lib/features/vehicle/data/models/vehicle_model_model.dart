// Path: lib/features/vehicle/data/models/vehicle_model_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_model_entity.dart';

class VehicleModelModel extends VehicleModelEntity {
  const VehicleModelModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.bodyType,
    required super.generation,
    required super.brandRef,
  });

  factory VehicleModelModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return VehicleModelModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      slug: data['slug'] ?? '',
      bodyType: data['body_type'] ?? '',
      generation: data['generation'] ?? '',
      brandRef: data['brand_ref'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'body_type': bodyType,
      'generation': generation,
      'brand_ref': brandRef,
    };
  }
}
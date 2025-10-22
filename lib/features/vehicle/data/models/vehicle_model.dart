// Path: lib/features/vehicle/data/models/vehicle_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/vehicle_entity.dart';

class VehicleModel extends VehicleEntity {
  const VehicleModel({
    required super.id,
    required super.modificationEngine,
    required super.fuelConsumption,
    required super.searchKeywords,
    required super.url,
    required super.yearRef,
    required super.scrapedAt,
  });

  factory VehicleModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Fuel consumption map'ini parse et
    final fuelData = data['fuel_consumption'] as Map<String, dynamic>? ?? {};
    final fuelConsumption = FuelConsumption(
      combined: (fuelData['combined'] as num?)?.toDouble() ?? 0.0,
      urban: (fuelData['urban'] as num?)?.toDouble() ?? 0.0,
      extraUrban: (fuelData['extra_urban'] as num?)?.toDouble() ?? 0.0,
    );

    // Search keywords array'ini parse et
    final searchKeywords = (data['search_keywords'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    return VehicleModel(
      id: snapshot.id,
      modificationEngine: data['modification_engine'] ?? '',
      fuelConsumption: fuelConsumption,
      searchKeywords: searchKeywords,
      url: data['url'] ?? '',
      yearRef: data['year_ref'] ?? '',
      scrapedAt: data['scraped_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modification_engine': modificationEngine,
      'fuel_consumption': {
        'combined': fuelConsumption.combined,
        'urban': fuelConsumption.urban,
        'extra_urban': fuelConsumption.extraUrban,
      },
      'search_keywords': searchKeywords,
      'url': url,
      'year_ref': yearRef,
      'scraped_at': scrapedAt,
    };
  }
}

// Eski yapı için backward compatibility
class VehicleClassModel extends VehicleClassEntity {
  const VehicleClassModel({
    required super.id,
    required super.name,
    required super.classId,
    required super.icon,
    required super.description,
  });

  factory VehicleClassModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return VehicleClassModel(
      id: snapshot.id,
      name: data['name'] ?? '',
      classId: data['classId'] ?? 1,
      icon: data['icon'] ?? 'directions_car',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'classId': classId,
      'icon': icon,
      'description': description,
    };
  }
}
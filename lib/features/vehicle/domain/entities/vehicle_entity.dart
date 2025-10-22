// Path: lib/features/vehicle/domain/entities/vehicle_entity.dart

class FuelConsumption {
  final double combined;
  final double urban;
  final double extraUrban;

  const FuelConsumption({
    required this.combined,
    required this.urban,
    required this.extraUrban,
  });

  @override
  String toString() => 'FuelConsumption(combined: ${combined}L/100km, urban: ${urban}L/100km, extraUrban: ${extraUrban}L/100km)';
}

class VehicleEntity {
  final String id;
  final String modificationEngine;
  final FuelConsumption fuelConsumption;
  final List<String> searchKeywords;
  final String url;
  final String yearRef;
  final String scrapedAt;

  const VehicleEntity({
    required this.id,
    required this.modificationEngine,
    required this.fuelConsumption,
    required this.searchKeywords,
    required this.url,
    required this.yearRef,
    required this.scrapedAt,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is VehicleEntity &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VehicleEntity(id: $id, engine: $modificationEngine, fuel: $fuelConsumption)';
}

// Eski yapı - backward compatibility için
class VehicleClassEntity {
  final String id;
  final String name;
  final int classId;
  final String icon;
  final String description;

  const VehicleClassEntity({
    required this.id,
    required this.name,
    required this.classId,
    required this.icon,
    required this.description,
  });
}
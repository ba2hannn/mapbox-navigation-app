// Path: lib/features/vehicle/domain/entities/vehicle_model_entity.dart

class VehicleModelEntity {
  final String id;
  final String name;
  final String slug;
  final String bodyType;
  final String generation;
  final String brandRef;

  const VehicleModelEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.bodyType,
    required this.generation,
    required this.brandRef,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is VehicleModelEntity &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VehicleModelEntity(id: $id, name: $name, bodyType: $bodyType)';
}
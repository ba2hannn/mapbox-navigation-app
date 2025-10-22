// Path: lib/features/vehicle/domain/entities/vehicle_brand_entity.dart

class VehicleBrandEntity {
  final String id;
  final String name;
  final String slug;

  const VehicleBrandEntity({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is VehicleBrandEntity &&
    runtimeType == other.runtimeType &&
    id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'VehicleBrandEntity(id: $id, name: $name, slug: $slug)';
}
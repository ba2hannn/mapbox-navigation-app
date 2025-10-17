import '../../domain/entities/location_entity.dart';

/// Location model for data layer
class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.accuracy,
    required super.timestamp,
  });

  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracy: entity.accuracy,
      timestamp: entity.timestamp,
    );
  }

  LocationEntity toEntity() {
    return LocationEntity(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
    );
  }
}

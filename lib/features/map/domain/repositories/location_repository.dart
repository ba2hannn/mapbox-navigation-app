import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../entities/failure.dart';

/// Location repository interface
abstract class LocationRepository {
  Future<Either<Failure, LocationEntity>> getCurrentLocation();
  Stream<LocationEntity> getLocationStream();
  Future<Either<Failure, bool>> requestPermission();
}

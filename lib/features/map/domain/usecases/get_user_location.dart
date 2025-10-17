import 'package:dartz/dartz.dart';
import '../entities/location_entity.dart';
import '../entities/failure.dart';
import '../repositories/location_repository.dart';

/// Use case for getting user location
class GetUserLocation {
  final LocationRepository repository;

  GetUserLocation(this.repository);

  Future<Either<Failure, LocationEntity>> call() async {
    return await repository.getCurrentLocation();
  }
}

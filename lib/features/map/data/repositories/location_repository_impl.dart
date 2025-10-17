import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/entities/failure.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_data_source.dart';

/// Implementation of LocationRepository
class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;

  LocationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(LocationServiceFailure());
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(LocationPermissionFailure());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(LocationPermissionFailure());
      }

      final location = await localDataSource.getCurrentLocation();
      return Right(location);
    } catch (e) {
      return const Left(LocationFetchFailure());
    }
  }

  @override
  Stream<LocationEntity> getLocationStream() {
    return localDataSource.getLocationStream();
  }

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final result = await localDataSource.requestPermission();
      return Right(result);
    } catch (e) {
      return const Left(LocationPermissionFailure());
    }
  }
}

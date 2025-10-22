// Path: lib/features/vehicle/data/repositories/vehicle_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/platform/network_info.dart';
import '../../domain/entities/vehicle_brand_entity.dart';
import '../../domain/entities/vehicle_model_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/year.dart';
import '../../domain/entities/body_type.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_data_source.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  VehicleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VehicleBrandEntity>>> getAllBrands() async {
    if (await networkInfo.isConnected) {
      try {
        final brands = await remoteDataSource.getAllBrands();
        return Right(brands);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<VehicleModelEntity>>> getModelsByBrand(String brandId) async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getModelsByBrand(brandId);
        return Right(models);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByModel(String modelId) async {
    if (await networkInfo.isConnected) {
      try {
        final vehicles = await remoteDataSource.getVehiclesByModel(modelId);
        return Right(vehicles);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Year>>> getYearsByModel(String modelId) async {
    if (await networkInfo.isConnected) {
      try {
        final years = await remoteDataSource.getYearsByModel(modelId);
        return Right(years);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<BodyType>>> getBodyTypesByModelAndYear(String modelId, String year) async {
    if (await networkInfo.isConnected) {
      try {
        final bodyTypes = await remoteDataSource.getBodyTypesByModelAndYear(modelId, year);
        return Right(bodyTypes);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String vehicleId) async {
    if (await networkInfo.isConnected) {
      try {
        final vehicle = await remoteDataSource.getVehicleById(vehicleId);
        return Right(vehicle);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  // Eski yapı için backward compatibility
  @override
  Future<Either<Failure, List<VehicleEntity>>> getAllVehicles() async {
    if (await networkInfo.isConnected) {
      try {
        final vehicles = await remoteDataSource.getAllVehicles();
        return Right(vehicles);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, VehicleEntity>> getVehicleByIdOld(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final vehicle = await remoteDataSource.getVehicleByIdOld(id);
        return Right(vehicle);
      } on NotFoundException catch (e) {
        return Left(NotFoundFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
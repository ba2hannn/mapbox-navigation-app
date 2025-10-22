// Path: lib/features/vehicle/domain/repositories/vehicle_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vehicle_brand_entity.dart';
import '../entities/vehicle_model_entity.dart';
import '../entities/vehicle_entity.dart';
import '../entities/year.dart';
import '../entities/body_type.dart';

abstract class VehicleRepository {
  // Yeni Firebase yapısı için
  Future<Either<Failure, List<VehicleBrandEntity>>> getAllBrands();
  Future<Either<Failure, List<VehicleModelEntity>>> getModelsByBrand(String brandId);
  Future<Either<Failure, List<VehicleEntity>>> getVehiclesByModel(String modelId);
  Future<Either<Failure, List<Year>>> getYearsByModel(String modelId);
  Future<Either<Failure, List<BodyType>>> getBodyTypesByModelAndYear(String modelId, String year);
  Future<Either<Failure, VehicleEntity?>> getVehicleById(String vehicleId);

  // Eski yapı için backward compatibility
  Future<Either<Failure, List<VehicleEntity>>> getAllVehicles();
  Future<Either<Failure, VehicleEntity>> getVehicleByIdOld(String id);
}
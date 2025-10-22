// Path: lib/features/vehicle/domain/usecases/get_models_by_brand.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_model_entity.dart';
import '../repositories/vehicle_repository.dart';

class GetModelsByBrand implements UseCase<List<VehicleModelEntity>, String> {
  final VehicleRepository repository;

  GetModelsByBrand(this.repository);

  @override
  Future<Either<Failure, List<VehicleModelEntity>>> call(String brandId) async {
    return await repository.getModelsByBrand(brandId);
  }
}
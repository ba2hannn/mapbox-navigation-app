// Path: lib/features/vehicle/domain/usecases/get_vehicles_by_model.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_entity.dart';
import '../repositories/vehicle_repository.dart';

class GetVehiclesByModel implements UseCase<List<VehicleEntity>, String> {
  final VehicleRepository repository;

  GetVehiclesByModel(this.repository);

  @override
  Future<Either<Failure, List<VehicleEntity>>> call(String modelId) async {
    return await repository.getVehiclesByModel(modelId);
  }
}
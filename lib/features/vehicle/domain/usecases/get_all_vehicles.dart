// Path: lib/features/vehicle/domain/usecases/get_all_vehicles.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_entity.dart';
import '../repositories/vehicle_repository.dart';

class GetAllVehicles implements UseCase<List<VehicleEntity>, NoParams> {
  final VehicleRepository repository;

  GetAllVehicles(this.repository);

  @override
  Future<Either<Failure, List<VehicleEntity>>> call(NoParams params) async {
    return await repository.getAllVehicles();
  }
}
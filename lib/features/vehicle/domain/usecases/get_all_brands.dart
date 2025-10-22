// Path: lib/features/vehicle/domain/usecases/get_all_brands.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vehicle_brand_entity.dart';
import '../repositories/vehicle_repository.dart';

class GetAllBrands implements UseCase<List<VehicleBrandEntity>, NoParams> {
  final VehicleRepository repository;

  GetAllBrands(this.repository);

  @override
  Future<Either<Failure, List<VehicleBrandEntity>>> call(NoParams params) async {
    return await repository.getAllBrands();
  }
}
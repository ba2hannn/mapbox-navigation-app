import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/year.dart';
import '../repositories/vehicle_repository.dart';

class GetYearsByModel {
  final VehicleRepository repository;

  GetYearsByModel(this.repository);

  Future<Either<Failure, List<Year>>> call(String modelId) async {
    return await repository.getYearsByModel(modelId);
  }
}
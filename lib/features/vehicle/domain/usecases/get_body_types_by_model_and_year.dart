import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/body_type.dart';
import '../repositories/vehicle_repository.dart';

class GetBodyTypesByModelAndYear {
  final VehicleRepository repository;

  GetBodyTypesByModelAndYear(this.repository);

  Future<Either<Failure, List<BodyType>>> call(String modelId, String year) async {
    return await repository.getBodyTypesByModelAndYear(modelId, year);
  }
}
// Path: lib/features/toll/domain/repositories/toll_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart' as core_failure; // Projendeki Failure sınıfının yolu
import '../entities/toll_cost_entity.dart';
import '../entities/toll_gate_entity.dart';

abstract class TollRepository {
  // Bütün aktif gişeleri getir
  Future<Either<core_failure.Failure, List<TollGateEntity>>> getAllTollGates();
  
  // İki gişe ID'sine göre ücreti getir
  Future<Either<core_failure.Failure, TollCostEntity>> getTollCost({
    required String entryGateId,
    required String exitGateId,
  });
}
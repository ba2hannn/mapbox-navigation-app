// Path: lib/features/toll/data/repositories/toll_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/platform/network_info.dart'; // Bu dosyayı da oluşturacağız
import '../../domain/entities/toll_cost_entity.dart';
import '../../domain/entities/toll_gate_entity.dart';
import '../../domain/repositories/toll_repository.dart';
import '../datasources/toll_remote_data_source.dart';

class TollRepositoryImpl implements TollRepository {
  final TollRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo; // İnternet bağlantısını kontrol etmek için

  TollRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TollGateEntity>>> getAllTollGates() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTollGates = await remoteDataSource.getAllTollGates();
        return Right(remoteTollGates);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, TollCostEntity>> getTollCost({
    required String entryGateId,
    required String exitGateId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteTollCost = await remoteDataSource.getTollCost(
          entryGateId: entryGateId,
          exitGateId: exitGateId,
        );
        return Right(remoteTollCost);
      } on NotFoundException catch(e) {
        // Bu bir sunucu hatası değil, "veri bulunamadı" durumudur.
        // Bunu özel bir Failure ile yönetebiliriz veya şimdilik ServerFailure kullanabiliriz.
        return Left(ServerFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure());
    }
  }
}
// Path: lib/features/toll/data/datasources/toll_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart'; // Bu dosyayı birazdan oluşturacağız
import '../models/toll_cost_model.dart';
import '../models/toll_gate_model.dart';

abstract class TollRemoteDataSource {
  Future<List<TollGateModel>> getAllTollGates();
  Future<TollCostModel> getTollCost({
    required String entryGateId,
    required String exitGateId,
  });
}

class TollRemoteDataSourceImpl implements TollRemoteDataSource {
  final FirebaseFirestore firestore;

  TollRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<TollGateModel>> getAllTollGates() async {
    try {
      final snapshot = await firestore.collection('gates').get();
      
      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) => TollGateModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw ServerException(message: "Gişe verileri alınamadı: $e");
    }
  }

  @override
  Future<TollCostModel> getTollCost({
    required String entryGateId,
    required String exitGateId,
  }) async {
    try {
      final snapshot = await firestore
          .collection('tolls')
          .where('entryGateName', isEqualTo: entryGateId)
          .where('exitGateName', isEqualTo: exitGateId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Bu durumda tersini de kontrol etmeliyiz (örn: Gebze-Akıncı)
        final reverseSnapshot = await firestore
            .collection('tolls')
            .where('entryGateName', isEqualTo: exitGateId)
            .where('exitGateName', isEqualTo: entryGateId)
            .limit(1)
            .get();

        if (reverseSnapshot.docs.isEmpty) {
          throw NotFoundException(message: "Belirtilen gişeler arasında bir ücret bulunamadı.");
        }
        return TollCostModel.fromSnapshot(reverseSnapshot.docs.first);
      }

      return TollCostModel.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      if (e is NotFoundException) rethrow; // Kendi hatamızı tekrar fırlat
      throw ServerException(message: "Gişe ücreti alınamadı: $e");
    }
  }
}
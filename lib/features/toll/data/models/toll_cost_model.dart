// Path: lib/features/toll/data/models/toll_cost_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/toll_cost_entity.dart';

class TollCostModel extends TollCostEntity {
  const TollCostModel({
    required super.entryGateId,
    required super.exitGateId,
    required super.prices,
    required super.highway,
  });

  factory TollCostModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    final pricesData = data['prices'] as Map<String, dynamic>? ?? {};
    
    // prices map'ini double'a çevir
    final prices = <String, double>{};
    pricesData.forEach((key, value) {
      prices[key] = (value as num?)?.toDouble() ?? 0.0;
    });

    return TollCostModel(
      entryGateId: data['entryGateName'] ?? '',
      exitGateId: data['exitGateName'] ?? '',
      prices: prices,
      highway: data['highway'] ?? '',
    );
  }
}
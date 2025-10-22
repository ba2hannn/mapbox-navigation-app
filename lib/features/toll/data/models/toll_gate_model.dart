// Path: lib/features/toll/data/models/toll_gate_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/toll_gate_entity.dart';

class TollGateModel extends TollGateEntity {
  const TollGateModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.highway,
    required super.isActive,
  });

  factory TollGateModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;
    return TollGateModel(
      id: data['id'] ?? snap.id,
      name: data['id'] ?? snap.id, // name = id
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lon'] as num?)?.toDouble() ?? 0.0,
      highway: data['highway'] ?? '',
      isActive: true, // Varsayılan olarak aktif
    );
  }
}
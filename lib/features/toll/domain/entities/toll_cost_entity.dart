// Path: lib/features/toll/domain/entities/toll_cost_entity.dart

import 'package:equatable/equatable.dart';

class TollCostEntity extends Equatable {
  final String entryGateId;
  final String exitGateId;
  final Map<String, double> prices; // class1, class2, class3, class4, class5
  final String highway;
  
  const TollCostEntity({
    required this.entryGateId,
    required this.exitGateId,
    required this.prices,
    required this.highway,
  });

  // Belirli bir araç sınıfı için fiyat döndür
  double getCostForClass(int vehicleClass) {
    final classKey = 'class$vehicleClass';
    return prices[classKey] ?? 0.0;
  }

  @override
  List<Object?> get props => [entryGateId, exitGateId, prices, highway];
}
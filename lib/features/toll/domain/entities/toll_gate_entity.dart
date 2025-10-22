// Path: lib/features/toll/domain/entities/toll_gate_entity.dart

import 'package:equatable/equatable.dart';

class TollGateEntity extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String highway;
  final bool isActive;

  const TollGateEntity({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.highway,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, highway, isActive];
}
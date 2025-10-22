// Path: lib/features/vehicle/presentation/bloc/vehicle_state.dart

import 'package:equatable/equatable.dart';
import '../../domain/entities/vehicle_brand_entity.dart';
import '../../domain/entities/vehicle_model_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/year.dart';
import '../../domain/entities/body_type.dart';

abstract class VehicleState extends Equatable {
  const VehicleState();

  @override
  List<Object> get props => [];
}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {}

class BrandsLoaded extends VehicleState {
  final List<VehicleBrandEntity> brands;

  const BrandsLoaded(this.brands);

  @override
  List<Object> get props => [brands];
}

class ModelsLoaded extends VehicleState {
  final List<VehicleModelEntity> models;

  const ModelsLoaded(this.models);

  @override
  List<Object> get props => [models];
}

class VehiclesLoaded extends VehicleState {
  final List<VehicleEntity> vehicles;

  const VehiclesLoaded(this.vehicles);

  @override
  List<Object> get props => [vehicles];
}

class YearsLoaded extends VehicleState {
  final List<Year> years;

  const YearsLoaded(this.years);

  @override
  List<Object> get props => [years];
}

class BodyTypesLoaded extends VehicleState {
  final List<BodyType> bodyTypes;

  const BodyTypesLoaded(this.bodyTypes);

  @override
  List<Object> get props => [bodyTypes];
}

class VehicleError extends VehicleState {
  final String message;

  const VehicleError(this.message);

  @override
  List<Object> get props => [message];
}
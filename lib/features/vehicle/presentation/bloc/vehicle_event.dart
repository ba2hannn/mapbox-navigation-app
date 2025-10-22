// Path: lib/features/vehicle/presentation/bloc/vehicle_event.dart

import 'package:equatable/equatable.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object> get props => [];
}

class LoadBrands extends VehicleEvent {}

class LoadModels extends VehicleEvent {
  final String brandId;

  const LoadModels(this.brandId);

  @override
  List<Object> get props => [brandId];
}

class LoadVehicles extends VehicleEvent {
  final String modelId;

  const LoadVehicles(this.modelId);

  @override
  List<Object> get props => [modelId];
}

class LoadYearsByModel extends VehicleEvent {
  final String modelId;

  const LoadYearsByModel(this.modelId);

  @override
  List<Object> get props => [modelId];
}

class LoadBodyTypesByModelAndYear extends VehicleEvent {
  final String modelId;
  final String year;

  const LoadBodyTypesByModelAndYear(this.modelId, this.year);

  @override
  List<Object> get props => [modelId, year];
}
// Path: lib/features/vehicle/presentation/bloc/vehicle_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_all_brands.dart';
import '../../domain/usecases/get_models_by_brand.dart';
import '../../domain/usecases/get_vehicles_by_model.dart';
import '../../domain/usecases/get_years_by_model.dart';
import '../../domain/usecases/get_body_types_by_model_and_year.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final GetAllBrands getAllBrands;
  final GetModelsByBrand getModelsByBrand;
  final GetVehiclesByModel getVehiclesByModel;
  final GetYearsByModel getYearsByModel;
  final GetBodyTypesByModelAndYear getBodyTypesByModelAndYear;

  VehicleBloc({
    required this.getAllBrands,
    required this.getModelsByBrand,
    required this.getVehiclesByModel,
    required this.getYearsByModel,
    required this.getBodyTypesByModelAndYear,
  }) : super(VehicleInitial()) {
    on<LoadBrands>(_onLoadBrands);
    on<LoadModels>(_onLoadModels);
    on<LoadVehicles>(_onLoadVehicles);
    on<LoadYearsByModel>(_onLoadYears);
    on<LoadBodyTypesByModelAndYear>(_onLoadBodyTypes);
  }

  Future<void> _onLoadBrands(LoadBrands event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    final result = await getAllBrands(NoParams());
    result.fold(
      (failure) => emit(VehicleError(failure.toString())),
      (brands) => emit(BrandsLoaded(brands)),
    );
  }

  Future<void> _onLoadModels(LoadModels event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    final result = await getModelsByBrand(event.brandId);
    result.fold(
      (failure) => emit(VehicleError(failure.toString())),
      (models) => emit(ModelsLoaded(models)),
    );
  }

  Future<void> _onLoadVehicles(LoadVehicles event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    final result = await getVehiclesByModel(event.modelId);
    result.fold(
      (failure) => emit(VehicleError(failure.toString())),
      (vehicles) => emit(VehiclesLoaded(vehicles)),
    );
  }

  Future<void> _onLoadYears(LoadYearsByModel event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    final result = await getYearsByModel(event.modelId);
    result.fold(
      (failure) => emit(VehicleError(failure.toString())),
      (years) => emit(YearsLoaded(years)),
    );
  }

  Future<void> _onLoadBodyTypes(LoadBodyTypesByModelAndYear event, Emitter<VehicleState> emit) async {
    emit(VehicleLoading());
    final result = await getBodyTypesByModelAndYear(event.modelId, event.year);
    result.fold(
      (failure) => emit(VehicleError(failure.toString())),
      (bodyTypes) => emit(BodyTypesLoaded(bodyTypes)),
    );
  }
}
// Path: lib/core/di/injection_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

// --- Feature: Map ---
import '../../features/map/data/datasources/location_local_data_source.dart';
import '../../features/map/data/repositories/location_repository_impl.dart';
import '../../features/map/domain/repositories/location_repository.dart';
import '../../features/map/domain/usecases/get_user_location.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';

// --- Feature: Toll ---
import '../../features/toll/domain/usecases/calculate_route_toll_cost.dart';
import '../../features/toll/domain/repositories/toll_repository.dart';
import '../../features/toll/data/datasources/toll_remote_data_source.dart';
import '../../features/toll/data/repositories/toll_repository_impl.dart';

// --- Feature: Vehicle ---
import '../../features/vehicle/data/datasources/vehicle_remote_data_source.dart';
import '../../features/vehicle/data/repositories/vehicle_repository_impl.dart';
import '../../features/vehicle/domain/repositories/vehicle_repository.dart';
import '../../features/vehicle/domain/usecases/get_all_vehicles.dart';
import '../../features/vehicle/domain/usecases/get_all_brands.dart';
import '../../features/vehicle/domain/usecases/get_models_by_brand.dart';
import '../../features/vehicle/domain/usecases/get_vehicles_by_model.dart';
import '../../features/vehicle/domain/usecases/get_years_by_model.dart';
import '../../features/vehicle/domain/usecases/get_body_types_by_model_and_year.dart';
import '../../features/vehicle/presentation/bloc/vehicle_bloc.dart';

// --- Core ---
import '../platform/network_info.dart';


final sl = GetIt.instance; // sl = Service Locator

/// Dependency injection setup
Future<void> init() async {
  // ######################################################################
  // #                          FEATURES                                  #
  // ######################################################################

  // ----------------- Feature: Map -----------------
  // Bloc
  sl.registerFactory(
    () => MapBloc(getUserLocation: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUserLocation(sl()));

  // Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(),
  );

  // ----------------- Feature: Toll -----------------
  // Use cases
  sl.registerLazySingleton(() => CalculateRouteTollCost(sl()));

  // Repository
  sl.registerLazySingleton<TollRepository>(
    () => TollRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<TollRemoteDataSource>(
    () => TollRemoteDataSourceImpl(firestore: sl()),
  );

  // ----------------- Feature: Vehicle -----------------
  // Bloc
  sl.registerFactory(
    () => VehicleBloc(
      getAllBrands: sl(),
      getModelsByBrand: sl(),
      getVehiclesByModel: sl(),
      getYearsByModel: sl(),
      getBodyTypesByModelAndYear: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAllVehicles(sl()));
  sl.registerLazySingleton(() => GetAllBrands(sl()));
  sl.registerLazySingleton(() => GetModelsByBrand(sl()));
  sl.registerLazySingleton(() => GetVehiclesByModel(sl()));
  sl.registerLazySingleton(() => GetYearsByModel(sl()));
  sl.registerLazySingleton(() => GetBodyTypesByModelAndYear(sl()));

  // Repository
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<VehicleRemoteDataSource>(
    () => VehicleRemoteDataSourceImpl(firestore: sl()),
  );

  // ######################################################################
  // #                             CORE                                   #
  // ######################################################################
  
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ######################################################################
  // #                           EXTERNAL                                 #
  // ######################################################################
  
  // Firebase Firestore
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  
  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}
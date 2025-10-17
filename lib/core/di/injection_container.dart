import 'package:get_it/get_it.dart';
import '../../features/map/presentation/bloc/map_bloc.dart';
import '../../features/map/domain/usecases/get_user_location.dart';
import '../../features/map/domain/repositories/location_repository.dart';
import '../../features/map/data/repositories/location_repository_impl.dart';
import '../../features/map/data/datasources/location_local_data_source.dart';

final sl = GetIt.instance;

/// Dependency injection setup
Future<void> init() async {
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
}

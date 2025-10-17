import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_location.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetUserLocation getUserLocation;

  MapBloc({required this.getUserLocation}) : super(const MapInitial()) {
    on<MapInitialized>(_onMapInitialized);
    on<MapUserLocationRequested>(_onUserLocationRequested);
  }

  Future<void> _onMapInitialized(
    MapInitialized event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapLoading());
    
    final result = await getUserLocation();
    
    result.fold(
      (failure) => emit(MapError(failure.message)),
      (location) => emit(MapLoaded(userLocation: location)),
    );
  }

  Future<void> _onUserLocationRequested(
    MapUserLocationRequested event,
    Emitter<MapState> emit,
  ) async {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      
      final result = await getUserLocation();
      
      result.fold(
        (failure) => emit(MapError(failure.message)),
        (location) => emit(currentState.copyWith(userLocation: location)),
      );
    }
  }
}

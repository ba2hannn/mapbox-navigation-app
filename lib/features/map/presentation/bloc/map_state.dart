import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entity.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  final LocationEntity? userLocation;
  final double zoom;

  const MapLoaded({
    this.userLocation,
    this.zoom = 12.0,
  });

  MapLoaded copyWith({
    LocationEntity? userLocation,
    double? zoom,
  }) {
    return MapLoaded(
      userLocation: userLocation ?? this.userLocation,
      zoom: zoom ?? this.zoom,
    );
  }

  @override
  List<Object?> get props => [userLocation, zoom];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}

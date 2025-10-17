import 'package:equatable/equatable.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class MapInitialized extends MapEvent {
  const MapInitialized();
}

class MapUserLocationRequested extends MapEvent {
  const MapUserLocationRequested();
}

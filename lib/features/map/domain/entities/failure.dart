import 'package:equatable/equatable.dart';

/// Base class for failures
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class LocationPermissionFailure extends Failure {
  const LocationPermissionFailure() : super('Konum izni reddedildi');
}

class LocationServiceFailure extends Failure {
  const LocationServiceFailure() : super('Konum servisi kapalı');
}

class LocationFetchFailure extends Failure {
  const LocationFetchFailure() : super('Konum alınamadı');
}

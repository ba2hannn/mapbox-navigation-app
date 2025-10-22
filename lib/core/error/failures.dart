// Path: lib/core/error/failures.dart

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

// Genel Hatalar
class ServerFailure extends Failure {
  final String message;

  const ServerFailure({this.message = 'Sunucu hatası oluştu.'});

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure({this.message = 'Önbellek hatası oluştu.'});
    
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
    final String message;

  const NetworkFailure({this.message = 'İnternet bağlantınızı kontrol edin.'});
    
  @override
  List<Object> get props => [message];
}

class NotFoundFailure extends Failure {
  final String message;

  const NotFoundFailure({this.message = 'İstenen veri bulunamadı.'});

  @override
  List<Object> get props => [message];
}
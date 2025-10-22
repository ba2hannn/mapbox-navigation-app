// Path: lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Bir sunucu hatası oluştu.'});
}

class CacheException implements Exception {
    final String message;
  CacheException({this.message = 'Bir önbellek hatası oluştu.'});
}

class NotFoundException implements Exception {
    final String message;
  NotFoundException({this.message = 'Veri bulunamadı.'});
}
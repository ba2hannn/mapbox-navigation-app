import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/location_cache_service.dart';
import '../models/location_model.dart';

/// Local data source for location
abstract class LocationLocalDataSource {
  Future<LocationModel> getCurrentLocation();
  Stream<LocationModel> getLocationStream();
  Future<bool> requestPermission();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  @override
  Future<LocationModel> getCurrentLocation() async {
    // Önce önbellekten kontrol et - çok hızlı
    final cachedLocation = await LocationCacheService.getCachedLocation();
    if (cachedLocation != null) {
      // Önbellekte varsa hemen döndür
      return LocationModel(
        latitude: cachedLocation.latitude,
        longitude: cachedLocation.longitude,
        accuracy: cachedLocation.accuracy,
        timestamp: cachedLocation.timestamp,
      );
    }
    
    // Önbellekte yoksa GPS'den al
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Yeni konumu önbelleğe kaydet
    await LocationCacheService.saveLocation(position);

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  @override
  Stream<LocationModel> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((position) => LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ));
  }

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }
}

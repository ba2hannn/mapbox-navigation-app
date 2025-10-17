import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationCacheService {
  static const String _lastLatKey = 'last_latitude';
  static const String _lastLngKey = 'last_longitude';
  static const String _lastTimeKey = 'last_location_time';
  
  // Konum 5 dakikadan eskiyse yeniden al
  static const int _cacheValidityMinutes = 5;

  // Son konumu kaydet
  static Future<void> saveLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lastLatKey, position.latitude);
    await prefs.setDouble(_lastLngKey, position.longitude);
    await prefs.setInt(_lastTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Önbellekteki konumu al (geçerliyse)
  static Future<Position?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lat = prefs.getDouble(_lastLatKey);
      final lng = prefs.getDouble(_lastLngKey);
      final time = prefs.getInt(_lastTimeKey);
      
      if (lat == null || lng == null || time == null) {
        return null;
      }
      
      // Önbellek geçerliliğini kontrol et
      final lastTime = DateTime.fromMillisecondsSinceEpoch(time);
      final now = DateTime.now();
      final difference = now.difference(lastTime);
      
      if (difference.inMinutes > _cacheValidityMinutes) {
        return null; // Önbellek eski
      }
      
      // Geçerli önbellek
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: lastTime,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (e) {
      return null;
    }
  }

  // Önbelleği temizle
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLatKey);
    await prefs.remove(_lastLngKey);
    await prefs.remove(_lastTimeKey);
  }
}

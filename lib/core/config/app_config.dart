/// Application configuration and constants
class AppConfig {
  // Mapbox Configuration
  static const String mapboxAccessToken = 
      'pk.eyJ1IjoiYmEyaGFubiIsImEiOiJjbGt0bGNvZjMwYW9kM2Zxb242ZHNjOXJlIn0.ChzsBNO4d7chTkTO5t5whA';
  
  // Map Settings - Türkiye Odaklı
  static const double defaultZoom = 6.0; // Türkiye geneli görünümü
  static const double defaultLatitude = 39.9334; // Ankara merkezi (Kızılay)
  static const double defaultLongitude = 32.8597; // Ankara merkezi
  static const double initialMapZoom = 6.5; // Başlangıç zoom seviyesi (Ankara merkezde büyük)
  
  // Türkiye sınırları (bounding box) - Harita bu alana kısıtlanabilir
  static const double turkeyMinLat = 34.0; // En güney (Akdeniz için genişletildi - Antalya, Hatay görünür)
  static const double turkeyMaxLat = 42.5; // En kuzey
  static const double turkeyMinLng = 25.5; // En batı
  static const double turkeyMaxLng = 45.5; // En doğu
  
  // Zoom seviyeleri
  static const double minZoom = 5.0; // Türkiye geneli minimum
  static const double maxZoom = 20.0; // Sokak seviyesi maksimum
  
  // Performance ayarları
  static const int tileCacheSize = 50; // MB - Türkiye için tile cache
  
  // App Info
  static const String appName = 'Rota App';
  static const String appVersion = '1.0.0';
}

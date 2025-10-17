import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/location_cache_service.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../map/presentation/pages/map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Paralel başlat: 5 saniye timer + konum izinleri
      await Future.wait([
        Future.delayed(const Duration(seconds: 5)), // 3'ten 5'e çıkarıldı
        _checkLocationPermissions(),
      ]);

      // Navigasyon
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => user != null 
              ? const MapScreen()
              : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Başlatma hatası: $e');
    }
  }

  Future<void> _checkLocationPermissions() async {
    try {
      // Önce önbellekte konum var mı kontrol et - çok hızlı
      final cachedLocation = await LocationCacheService.getCachedLocation();
      if (cachedLocation != null) {
        debugPrint('✅ Önbellekten konum alındı: ${cachedLocation.latitude}, ${cachedLocation.longitude}');
        return;
      }
      
      // Konum servisi ve izin kontrolü
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) return;

      // Konumu al (splash 3 saniye olduğu için bekleyebiliriz)
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          await LocationCacheService.saveLocation(position);
          debugPrint('✅ Konum alındı ve kaydedildi: ${position.latitude}, ${position.longitude}');
        } catch (e) {
          debugPrint('Konum alınamadı: $e');
        }
      }
    } catch (e) {
      debugPrint('Konum hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/arkaplan2.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'features/map/presentation/bloc/map_bloc.dart';
import 'features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/map/presentation/pages/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Mapbox
  MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  
  // Initialize dependency injection
  await di.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => di.sl<MapBloc>()),
        BlocProvider(create: (context) => di.sl<VehicleBloc>()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/map': (context) => const MapScreen(),
        },
      ),
    );
  }
}

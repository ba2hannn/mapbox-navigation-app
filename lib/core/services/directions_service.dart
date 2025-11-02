import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../di/injection_container.dart'; 
import '../models/route_summary.dart'; // Yeni RouteSummary modelini import et
import '../../features/toll/domain/usecases/calculate_route_toll_cost.dart';

/// Rota tipi
enum RouteType {
  fast,     // Hızlı rota (ücretli yol dahil)
  tollFree, // Ücretsiz rota (ücretli yol hariç)
  city,     // Şehir içi rota (motorway ve tolls hariç)
}

class DirectionsService {
  final CalculateRouteTollCost _calculateRouteTollCost = sl<CalculateRouteTollCost>();
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  Future<DirectionsResponse?> _getSingleRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-traffic',
    String exclude = '',
  }) async {
    try {
      String excludeParam = exclude.isNotEmpty ? '&exclude=$exclude' : '';
      
      final url = Uri.parse(
          '$_baseUrl/$profile/$startLng,$startLat;$endLng,$endLat'
          '?access_token=${AppConfig.mapboxAccessToken}'
          '&geometries=geojson&overview=full&steps=true&alternatives=true'
          '&language=tr&annotations=distance,duration,speed,congestion$excludeParam');
          
      debugPrint('🗺️ Directions API çağrısı: ${exclude.isNotEmpty ? exclude.replaceAll(',', '+') : "Hızlı"} Rota');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final directionsResponse = DirectionsResponse.fromJson(data);
        
        // Sadece ücretli yollar dahil rotalar için gişe hesapla
        if (!exclude.contains('toll') && directionsResponse.routes.isNotEmpty) {
          final route = directionsResponse.routes.first;
          final tollCost = await _calculateToll(route);
          route.tollCost = tollCost;
        }

        debugPrint('✅ Rota başarıyla alındı');
        return directionsResponse;
      } else {
        debugPrint('❌ Directions API hatası: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Rota alma hatası: $e');
      return null;
    }
  }
  
  Future<List<Route>> getMultipleRoutes({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final routes = <Route>[];
    
    final responses = await Future.wait([
      _getSingleRoute(
        startLat: startLat, startLng: startLng, endLat: endLat, endLng: endLng,
        profile: 'driving-traffic', exclude: '',
      ),
      _getSingleRoute(
        startLat: startLat, startLng: startLng, endLat: endLat, endLng: endLng,
        profile: 'driving-traffic', exclude: 'toll',
      ),
      _getSingleRoute(
        startLat: startLat, startLng: startLng, endLat: endLat, endLng: endLng,
        profile: 'driving-traffic', exclude: 'motorway,toll',
      ),
    ]);

    // 1. Fast route
    final fastResponse = responses[0];
    if (fastResponse != null && fastResponse.routes.isNotEmpty) {
      final fastRoute = fastResponse.routes.first;
      fastRoute.routeType = RouteType.fast;
      fastRoute.summary = _analyzeRoute(fastRoute);
      routes.add(fastRoute);
    }
    
    // 2. Toll-free route
    final tollFreeResponse = responses[1];
    if (tollFreeResponse != null && tollFreeResponse.routes.isNotEmpty) {
      final tollFreeRoute = tollFreeResponse.routes.first;
      tollFreeRoute.routeType = RouteType.tollFree;
      tollFreeRoute.summary = _analyzeRoute(tollFreeRoute);
      routes.add(tollFreeRoute);
    }

    // 3. City route (motorway and toll free)
    final cityResponse = responses[2];
    if (cityResponse != null && cityResponse.routes.isNotEmpty) {
      final cityRoute = cityResponse.routes.first;
      cityRoute.routeType = RouteType.city;
      cityRoute.summary = _analyzeRoute(cityRoute);
      routes.add(cityRoute);
    }
    
    debugPrint('✅ Toplam ${routes.length} rota (gişe ücretleri ve özetleriyle) oluşturuldu');
    return routes;
  }

  Future<double> _calculateToll(Route route) async {
    final tollCostResult = await _calculateRouteTollCost(
      RouteTollParams(route: route, vehicleClass: 1), // Varsayılan araç sınıfı: 1 (otomobil)
    );

    return tollCostResult.fold(
      (failure) {
        debugPrint("DirectionsService: Gişe ücreti hesaplama başarısız. Sonuç: 0.0");
        return 0.0;
      },
      (cost) => cost,
    );
  }

  /// Bir rotayı analiz edip tünel, köprü, feribot gibi özelliklerini çıkarır.
  RouteSummary _analyzeRoute(Route route) {
    final features = <RouteFeature>[];
    bool hasFerry = false;
    final Set<String> processedFeatureNames = {};

    for (final leg in route.legs) {
      for (final step in leg.steps) {
        String? featureType;
        
        // 1. Feribot kontrolü (en öncelikli)
        if (step.maneuverType?.contains('ferry') ?? step.mode == 'ferry') {
          featureType = 'ferry';
          hasFerry = true;
        } else {
          // 2. Tünel veya Köprü kontrolü
          // Bir adımın içindeki intersection'ların çoğunluğu ne ise, adım odur.
          final classesInStep = step.intersections.expand((i) => i.classes).toList();
          if (classesInStep.where((c) => c == 'tunnel').length > classesInStep.length / 2) {
            featureType = 'tunnel';
          } else if (classesInStep.where((c) => c == 'bridge').length > classesInStep.length / 2) {
            featureType = 'bridge';
          }
        }
        
        // Eğer bir özellik bulunduysa ve daha önce işlenmediyse listeye ekle
        if (featureType != null) {
          final featureName = step.name.isNotEmpty ? step.name : "İsimsiz ${featureType.capitalize()}";
          if (!processedFeatureNames.contains(featureName)) {
            features.add(RouteFeature(
                name: featureName, 
                type: featureType, 
                distance: step.distance
            ));
            processedFeatureNames.add(featureName);
          }
        }
      }
    }

    return RouteSummary(
      features: features,
      tunnelCount: features.where((f) => f.type == 'tunnel').length,
      bridgeCount: features.where((f) => f.type == 'bridge').length,
      hasFerry: hasFerry,
    );
  }
}

class DirectionsResponse {
  final List<Route> routes;
  final String code;

  DirectionsResponse({required this.routes, required this.code});

  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    var routesList = <Route>[];
    if (json['routes'] != null && json['routes'] is List) {
      routesList = (json['routes'] as List)
          .map((routeJson) => Route.fromJson(routeJson))
          .toList();
    }
    return DirectionsResponse(
      routes: routesList,
      code: json['code'] ?? '',
    );
  }
}

class Route {
  final double distance;
  final double duration;
  final List<List<double>> geometry;
  final List<RouteLeg> legs;
  final String? weightName;
  final List<String>? congestion; // Trafik yoğunluğu verileri
  RouteType? routeType;
  double? tollCost;
  RouteSummary? summary;
  final List<String>? missingTollSegments; // Eksik ücret segmentleri

  Route({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.legs,
    this.weightName,
    this.congestion,
    this.routeType,
    this.tollCost,
    this.summary,
    this.missingTollSegments,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    var geometryCoords = <List<double>>[];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      try {
        geometryCoords = (json['geometry']['coordinates'] as List)
            .map((coord) => List<double>.from((coord as List).map((e) => (e as num).toDouble())))
            .toList();
      } catch(e) {
         debugPrint("❌ Geometri verisi ayrıştırılırken hata: $e");
      }
    }

    var legsList = <RouteLeg>[];
    if (json['legs'] != null && json['legs'] is List) {
      legsList = (json['legs'] as List)
          .map((legJson) => RouteLeg.fromJson(legJson))
          .toList();
    }

    var congestionList = <String>[];
    if (json['legs'] != null && json['legs'] is List && (json['legs'] as List).isNotEmpty) {
      final firstLeg = json['legs'][0];
      if (firstLeg['annotation'] != null && firstLeg['annotation']['congestion'] != null) {
        congestionList = List<String>.from(firstLeg['annotation']['congestion']);
      }
    }

    return Route(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: geometryCoords,
      legs: legsList,
      weightName: json['weight_name'],
      congestion: congestionList.isNotEmpty ? congestionList : null,
    );
  }
  
  String get distanceText {
    if (distance < 1000) return '${distance.toInt()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
  
  String get durationText {
    final minutes = (duration / 60).toInt();
    if (minutes < 60) return '$minutes dk';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours sa $remainingMinutes dk';
  }
}

class RouteLeg {
  final double distance;
  final double duration;
  final List<RouteStep> steps;

  RouteLeg({
    required this.distance,
    required this.duration,
    required this.steps,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    var stepsList = <RouteStep>[];
    if (json['steps'] != null && json['steps'] is List) {
      stepsList = (json['steps'] as List)
          .map((stepJson) => RouteStep.fromJson(stepJson))
          .toList();
    }
    return RouteLeg(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      steps: stepsList,
    );
  }
}

class RouteStep {
  final double distance;
  final double duration;
  final List<List<double>> geometry;
  final String name;
  final String? instruction;
  final String? maneuverType;
  final String mode;
  final List<Intersection> intersections;

  RouteStep({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.name,
    this.instruction,
    this.maneuverType,
    required this.mode,
    required this.intersections,
  });
  
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    var geometryCoords = <List<double>>[];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
       try {
          geometryCoords = (json['geometry']['coordinates'] as List)
              .map((coord) => List<double>.from((coord as List).map((e) => (e as num).toDouble())))
              .toList();
       } catch (e) {
          debugPrint("❌ Step Geometri verisi ayrıştırılırken hata: $e");
       }
    }
    
    var intersectionsList = <Intersection>[];
    if (json['intersections'] != null && json['intersections'] is List) {
      intersectionsList = (json['intersections'] as List)
          .map((iJson) => Intersection.fromJson(iJson))
          .toList();
    }

    return RouteStep(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      geometry: geometryCoords,
      name: json['name'] ?? '',
      instruction: json['maneuver']?['instruction'],
      maneuverType: json['maneuver']?['type'],
      mode: json['mode'] ?? 'driving',
      intersections: intersectionsList,
    );
  }
}

class Intersection {
  final TollCollection? tollCollection;
  final List<double> location;
  final List<String> classes;

  Intersection({
    this.tollCollection, 
    required this.location,
    required this.classes,
  });

  factory Intersection.fromJson(Map<String, dynamic> json) {
    var classList = <String>[];
    if (json['classes'] != null && json['classes'] is List) {
      classList = List<String>.from(json['classes']);
    }

    return Intersection(
      tollCollection: json['toll_collection'] != null
          ? TollCollection.fromJson(json['toll_collection'])
          : null,
      location: List<double>.from((json['location'] as List).map((e) => (e as num).toDouble())),
      classes: classList,
    );
  }
}

class TollCollection {
  final String name;
  final String type;

  TollCollection({required this.name, required this.type});

  factory TollCollection.fromJson(Map<String, dynamic> json) {
    return TollCollection(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

// String'in ilk harfini büyük yapmak için küçük bir extension
extension StringExtension on String {
    String capitalize() {
      if (isEmpty) return "";
      return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
    }
}
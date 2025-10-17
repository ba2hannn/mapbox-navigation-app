import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

class DirectionsService {
  // Mapbox Directions API base URL
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  
  /// İki nokta arasında rota al
  /// 
  /// [startLat] Başlangıç noktası enlem
  /// [startLng] Başlangıç noktası boylam
  /// [endLat] Bitiş noktası enlem
  /// [endLng] Bitiş noktası boylam
  /// [profile] Rota profili: driving-traffic (varsayılan), driving, walking, cycling
  Future<DirectionsResponse?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving-traffic',
  }) async {
    try {
      // API URL oluştur
      final url = Uri.parse(
        '$_baseUrl/$profile/$startLng,$startLat;$endLng,$endLat'
        '?access_token=${AppConfig.mapboxAccessToken}'
        '&geometries=geojson'
        '&overview=full'
        '&steps=true'
        '&alternatives=true' // Alternatif rotalar
        '&language=tr' // Türkçe yönlendirmeler
      );
      
      debugPrint('🗺️ Directions API çağrısı: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Rota başarıyla alındı');
        return DirectionsResponse.fromJson(data);
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
}

/// Directions API yanıtı
class DirectionsResponse {
  final List<Route> routes;
  final String code;
  
  DirectionsResponse({
    required this.routes,
    required this.code,
  });
  
  factory DirectionsResponse.fromJson(Map<String, dynamic> json) {
    return DirectionsResponse(
      routes: (json['routes'] as List)
          .map((route) => Route.fromJson(route))
          .toList(),
      code: json['code'] ?? '',
    );
  }
}

/// Rota bilgisi
class Route {
  final double distance; // metre
  final double duration; // saniye
  final List<List<double>> geometry; // [[lng, lat], [lng, lat], ...]
  final List<RouteLeg> legs;
  final String? weightName;
  
  Route({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.legs,
    this.weightName,
  });
  
  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      geometry: (json['geometry']['coordinates'] as List)
          .map((coord) => [
                (coord[0] as num).toDouble(),
                (coord[1] as num).toDouble(),
              ])
          .toList(),
      legs: (json['legs'] as List)
          .map((leg) => RouteLeg.fromJson(leg))
          .toList(),
      weightName: json['weight_name'],
    );
  }
  
  /// Mesafeyi okunabilir formata çevir
  String get distanceText {
    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
  
  /// Süreyi okunabilir formata çevir
  String get durationText {
    final minutes = (duration / 60).toInt();
    if (minutes < 60) {
      return '$minutes dk';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours sa $remainingMinutes dk';
    }
  }
}

/// Rota parçası (leg)
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
    return RouteLeg(
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      steps: (json['steps'] as List)
          .map((step) => RouteStep.fromJson(step))
          .toList(),
    );
  }
}

/// Rota adımı (step)
class RouteStep {
  final double distance;
  final double duration;
  final List<List<double>> geometry;
  final String name;
  final String? instruction;
  final String? maneuverType;
  
  RouteStep({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.name,
    this.instruction,
    this.maneuverType,
  });
  
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      geometry: (json['geometry']['coordinates'] as List)
          .map((coord) => [
                (coord[0] as num).toDouble(),
                (coord[1] as num).toDouble(),
              ])
          .toList(),
      name: json['name'] ?? '',
      instruction: json['maneuver']?['instruction'],
      maneuverType: json['maneuver']?['type'],
    );
  }
}

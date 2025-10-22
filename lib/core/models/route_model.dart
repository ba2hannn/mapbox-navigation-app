// Path: lib/core/models/route_model.dart

class CustomRoute {
  final double distance; // metre
  final double duration; // saniye
  final List<List<double>> geometry; // [[lng, lat], [lng, lat], ...]
  final double? tollCost; // Gişe ücreti, nullable olabilir

  CustomRoute({
    required this.distance,
    required this.duration,
    required this.geometry,
    this.tollCost,
  });

  // Mapbox'tan gelen veriden kendi modelimizi oluşturmak için factory constructor.
  // `mapboxRouteData` Mapbox'tan gelen JSON yanıtının 'routes'[0] kısmıdır.
  factory CustomRoute.fromMapbox(Map<String, dynamic> mapboxRouteData) {
    // Polyline decoding işlemi burada yapılır veya geometry direkt alınır.
    // Bu kısım senin mevcut directions_service'indeki mantığa göre şekillenecek.
    final geometry = mapboxRouteData['geometry']['coordinates'] as List;
    final List<List<double>> decodedGeometry = geometry.map((point) {
      return (point as List).map((e) => (e as num).toDouble()).toList();
    }).toList();

    return CustomRoute(
      distance: (mapboxRouteData['distance'] as num).toDouble(),
      duration: (mapboxRouteData['duration'] as num).toDouble(),
      geometry: decodedGeometry,
    );
  }

  // Ücret hesaplandıktan sonra yeni bir nesne oluşturmak için yardımcı metod.
  CustomRoute copyWith({
    double? tollCost,
  }) {
    return CustomRoute(
      distance: distance,
      duration: duration,
      geometry: geometry,
      tollCost: tollCost ?? this.tollCost,
    );
  }
}
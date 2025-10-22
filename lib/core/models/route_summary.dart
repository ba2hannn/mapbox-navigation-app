// lib/core/models veya entities altına eklenebilir.
class RouteFeature {
  final String name;
  final String type; // 'tunnel', 'bridge', 'ferry'
  final double distance; // Bu özelliğin uzunluğu

  RouteFeature({required this.name, required this.type, required this.distance});
}

class RouteSummary {
  final List<RouteFeature> features;
  final int tunnelCount;
  final int bridgeCount;
  final bool hasFerry;

  RouteSummary({
    this.features = const [],
    this.tunnelCount = 0,
    this.bridgeCount = 0,
    this.hasFerry = false,
  });
}
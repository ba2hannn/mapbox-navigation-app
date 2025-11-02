import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/map_controls.dart';
import '../../../../core/widgets/map_layer_selector.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/animated_notification.dart';
import '../../../../core/services/directions_service.dart' as directions;
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/fuel_cost_service.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/services/saved_places_service.dart';
import '../../../../core/services/elevation_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import 'search_and_route_screen.dart';
import '../../../trips/presentation/widgets/trip_recording_dialog.dart';
import '../../../trips/presentation/widgets/trip_completion_dialog.dart';
import '../../../trips/data/services/trip_service.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../domain/entities/location_entity.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  bool _hasZoomedToLocation = false;
  bool _showLocationButton = false;
  Point? _userLocationPoint;
  String _currentMapStyle = 'STANDARD';
  User? _currentUser;
  bool _showUI = false;
  bool _showTraffic = false;

  GeocodingResult? _origin;
  GeocodingResult? _destination;
  directions.Route? _currentRoute;
  bool _isRouteActive = false;
  String? _currentTripId;

  List<directions.Route> _availableRoutes = [];
  int _selectedRouteIndex = 0;
  bool _isInRoutePreview = false;

  // Fuel data cache - route index ile eşleştirme
  final Map<int, Map<String, double>> _fuelDataCache = {};

  late AnimationController _bottomSheetController;
  double _bottomSheetPosition = 0.0;
  final double _minBottomSheetHeight = 140.0;
  final double _maxBottomSheetHeight = 600.0;
  final double _contentSafeZone = 120.0;

  List<GeocodingResult> _recentSearches = [];
  List<SavedPlace> _savedPlaces = [];

  // Servisler
  final TripService _tripService = TripService();
  final FuelCostService _fuelCostService = FuelCostService();
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  final SavedPlacesService _savedPlacesService = SavedPlacesService();
  late final AnalyticsService _analyticsService;
  late final FirebaseFirestore _firestore;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    context.read<MapBloc>().add(const MapInitialized());
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeServices();
    _loadRecentSearches();
    _loadSavedPlaces();
    _loadTripCompletionSettings();
  }

  Future<void> _initializeServices() async {
    _firestore = FirebaseFirestore.instance;
    _prefs = await SharedPreferences.getInstance();
    _analyticsService = AnalyticsService(_firestore, _prefs);
    await _analyticsService.initialize();
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  void _onMapScroll(MapContentGestureContext context) {
    _checkIfUserMovedAway();
  }

  Future<void> _checkIfUserMovedAway() async {
    if (_userLocationPoint == null || _mapboxMap == null) return;
    final cameraState = await _mapboxMap!.getCameraState();
    // HATA DÜZELTME: Değişken adındaki yazım hatası düzeltildi.
    final double dx = (cameraState.center.coordinates.lng - _userLocationPoint!.coordinates.lng).toDouble();
    final double dy = (cameraState.center.coordinates.lat - _userLocationPoint!.coordinates.lat).toDouble();
    
    final double distance = dx * dx + dy * dy;
    const double threshold = 0.0001;
    if (mounted && (distance > threshold) != _showLocationButton) {
      setState(() {
        _showLocationButton = distance > threshold;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapError) {
            NotificationHelper.show(context, state.message, isError: true);
          }
          if (state is MapLoaded && state.userLocation != null) {
            _userLocationPoint = Point(coordinates: Position(state.userLocation!.longitude, state.userLocation!.latitude));
            if (!_hasZoomedToLocation) {
              _hasZoomedToLocation = true;
              _showLocationButton = false;
              _animatedZoomToLocation(state.userLocation!.latitude, state.userLocation!.longitude);
            }
            // Konum güncellemesi geldiğinde kaydedilen yerlere yaklaşımı kontrol et
            _checkProximityToSavedPlaces(state.userLocation!);
          }
        },
        builder: (context, state) {
          final currentBottomSheetHeight = _isInRoutePreview ? 0 : _minBottomSheetHeight;
          return Stack(
            children: [
              GestureDetector(
                onLongPressStart: _onMapLongPress,
                onTapUp: _onMapTap,
                child: MapWidget(
                  key: const ValueKey('mapWidget'),
                  cameraOptions: CameraOptions(
                    center: Point(coordinates: Position(AppConfig.defaultLongitude, AppConfig.defaultLatitude)),
                    zoom: AppConfig.initialMapZoom,
                  ),
                  styleUri: MapboxStyles.STANDARD,
                  onMapCreated: _onMapCreated,
                  onScrollListener: _onMapScroll,
                ),
              ),
              if (state is MapLoading) const Center(child: CircularProgressIndicator()),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 3500),
                curve: Curves.easeInOutCubic,
                top: _showUI ? 0 : -100,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 3500),
                  opacity: _showUI ? 1.0 : 0.0,
                  child: _buildAppBar(context),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 3500),
                curve: Curves.easeInOutCubic,
                top: 120,
                right: _showUI ? 16 : -100,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 3500),
                  opacity: _showUI ? 1.0 : 0.0,
                  child: _buildRightControls(),
                ),
              ),
              if (_showLocationButton)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  bottom: currentBottomSheetHeight + 12,
                  right: _showUI ? 16 : -100,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showUI ? 1.0 : 0.0,
                    child: _buildLocationButton(context, state),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 3500),
                  offset: _showUI ? Offset.zero : const Offset(0, 1),
                  curve: Curves.easeInOutCubic,
                  child: _buildBottomSheet(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              AppConfig.appName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightControls() {
    return Column(
      children: [
        MapControlButton(
          icon: Icons.explore,
          tooltip: 'Kuzeyi Sıfırla',
          onTap: () async {
            if (_mapboxMap == null) return;
            await _mapboxMap!.flyTo(CameraOptions(bearing: 0), MapAnimationOptions(duration: 300));
          },
        ),
        const SizedBox(height: 8),
        MapControlButton(
          icon: Icons.add,
          tooltip: 'Yakınlaştır',
          onTap: () async {
            if (_mapboxMap == null) return;
            final cameraState = await _mapboxMap!.getCameraState();
            _mapboxMap!.flyTo(CameraOptions(zoom: cameraState.zoom + 1), MapAnimationOptions(duration: 300));
          },
        ),
        const SizedBox(height: 8),
        MapControlButton(
          icon: Icons.remove,
          tooltip: 'Uzaklaştır',
          onTap: () async {
            if (_mapboxMap == null) return;
            final cameraState = await _mapboxMap!.getCameraState();
            _mapboxMap!.flyTo(CameraOptions(zoom: cameraState.zoom - 1), MapAnimationOptions(duration: 300));
          },
        ),
        const SizedBox(height: 16),
        MapControlButton(
          icon: _showTraffic ? Icons.traffic : Icons.traffic_outlined,
          tooltip: _showTraffic ? 'Trafiği Gizle' : 'Trafiği Göster',
          onTap: _toggleTraffic,
          isActive: _showTraffic,
        ),
        const SizedBox(height: 8),
        MapControlButton(
          icon: Icons.layers,
          tooltip: 'Harita Katmanı',
          onTap: _showLayerSelector,
        ),
      ],
    );
  }

  void _showLayerSelector() {
    showDialog(
      context: context,
      builder: (context) => MapLayerSelector(
        currentLayer: _currentMapStyle,
        onLayerSelected: (layerKey) {
          setState(() => _currentMapStyle = layerKey);
          Navigator.of(context).pop();
          _changeMapStyle(layerKey);
        },
      ),
    );
  }

  void _changeMapStyle(String styleKey) async {
    if (_mapboxMap == null) return;
    String styleUri;
    switch (styleKey) {
      case 'STANDARD': styleUri = MapboxStyles.STANDARD; break;
      case 'STANDARD_SATELLITE': styleUri = MapboxStyles.SATELLITE_STREETS; break;
      case 'MAPBOX_STREETS': styleUri = MapboxStyles.MAPBOX_STREETS; break;
      case 'LIGHT': styleUri = MapboxStyles.LIGHT; break;
      case 'DARK': styleUri = MapboxStyles.DARK; break;
      case 'OUTDOORS': styleUri = MapboxStyles.OUTDOORS; break;
      case 'SATELLITE': styleUri = MapboxStyles.SATELLITE; break;
      case 'SATELLITE_STREETS': styleUri = MapboxStyles.SATELLITE_STREETS; break;
      default: styleUri = MapboxStyles.STANDARD;
    }
    final wasTrafficEnabled = _showTraffic;
    await _mapboxMap!.loadStyleURI(styleUri);
    if (wasTrafficEnabled) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _addTrafficLayers();
    }

    // Harita katmanı değiştiğinde marker'ları yeniden ekle
    await _updateSavedPlacesMarkers();
  }

  void _openProfilePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProfileScreen(),
    );
  }

  Widget _buildLocationButton(BuildContext context, MapState state) {
    return AnimatedMapButton(
      visible: _showLocationButton,
      child: MapControlButton(
        icon: Icons.my_location_rounded,
        tooltip: 'Konuma git',
        onTap: () async {
          setState(() => _showLocationButton = false);
          context.read<MapBloc>().add(const MapUserLocationRequested());
          await Future.delayed(const Duration(milliseconds: 100));
          if (_userLocationPoint != null) {
            await _moveToLocationFast(_userLocationPoint!.coordinates.lat.toDouble(), _userLocationPoint!.coordinates.lng.toDouble());
          }
        },
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.setBounds(CameraBoundsOptions(
      bounds: CoordinateBounds(
        southwest: Point(coordinates: Position(AppConfig.turkeyMinLng, AppConfig.turkeyMinLat)),
        northeast: Point(coordinates: Position(AppConfig.turkeyMaxLng, AppConfig.turkeyMaxLat)),
        infiniteBounds: false,
      ),
      minZoom: AppConfig.minZoom,
      maxZoom: AppConfig.maxZoom,
    ));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));

    // Harita oluşturulduktan sonra kaydedilen yer marker'larını ekle
    await _updateSavedPlacesMarkers();
  }

  Future<void> _addTrafficLayers() async {
    if (_mapboxMap == null) return;
    try {
      await _mapboxMap!.style.addSource(VectorSource(id: 'mapbox-traffic-source', url: 'mapbox://mapbox.mapbox-traffic-v1'));
      await _mapboxMap!.style.addLayer(LineLayer(id: 'traffic-moderate', sourceId: 'mapbox-traffic-source', sourceLayer: 'traffic', filter: ['==', ['get', 'congestion'], 'moderate'], lineWidth: 2.5, lineColor: Colors.yellow.toARGB32()));
      await _mapboxMap!.style.addLayer(LineLayer(id: 'traffic-heavy', sourceId: 'mapbox-traffic-source', sourceLayer: 'traffic', filter: ['==', ['get', 'congestion'], 'heavy'], lineWidth: 2.5, lineColor: Colors.orange.toARGB32()));
      await _mapboxMap!.style.addLayer(LineLayer(id: 'traffic-severe', sourceId: 'mapbox-traffic-source', sourceLayer: 'traffic', filter: ['==', ['get', 'congestion'], 'severe'], lineWidth: 2.5, lineColor: Colors.red.toARGB32()));
      debugPrint('✅ Trafik katmanları eklendi');
    } catch (e) {
      debugPrint('❌ Trafik katmanı ekleme hatası: $e');
    }
  }

  Future<void> _removeTrafficLayers() async {
    if (_mapboxMap == null) return;
    try {
      await _mapboxMap!.style.removeStyleLayer('traffic-moderate');
      await _mapboxMap!.style.removeStyleLayer('traffic-heavy');
      await _mapboxMap!.style.removeStyleLayer('traffic-severe');
      await _mapboxMap!.style.removeStyleSource('mapbox-traffic-source');
      debugPrint('✅ Trafik katmanları kaldırıldı');
    } catch (e) {
      debugPrint('Layer silme hatası (normal olabilir): $e');
    }
  }

  Future<void> _toggleTraffic() async {
    if (_mapboxMap == null) return;
    final previousState = _showTraffic;
    setState(() => _showTraffic = !_showTraffic);
    try {
      if (_showTraffic) {
        await _addTrafficLayers();
        // Başarılı olduktan sonra UI'ı güncelle
        if (mounted) {
          setState(() {}); // Force update UI
          NotificationHelper.show(context, 'Trafik yoğunluğu gösteriliyor');
        }
      } else {
        await _removeTrafficLayers();
        // Başarılı olduktan sonra UI'ı güncelle
        if (mounted) setState(() {}); // Force update UI
      }
    } catch (e) {
      debugPrint('❌ Trafik toggle hatası: $e');
      // Hata durumunda önceki state'e geri dön
      if (mounted) {
        setState(() => _showTraffic = previousState);
        NotificationHelper.show(context, 'Trafik bilgisi yüklenemedi', isError: true);
      }
    }
  }

  Future<void> _drawRoute(directions.Route route) async {
    if (_mapboxMap == null) return;
    try {
      await _clearAllRoutes();
      final coordinates = route.geometry.map((c) => [c[0], c[1]]).toList();
      final geoJson = {'type': 'Feature', 'geometry': {'type': 'LineString', 'coordinates': coordinates}};
      await _mapboxMap!.style.addSource(GeoJsonSource(id: 'route-source', data: json.encode(geoJson)));
      await _mapboxMap!.style.addLayer(LineLayer(id: 'route-line-shadow', sourceId: 'route-source', lineWidth: 8.0, lineColor: Colors.black.withOpacity(0.5).toARGB32(), lineBlur: 4.0));
      await _mapboxMap!.style.addLayer(LineLayer(id: 'route-line', sourceId: 'route-source', lineWidth: 6.0, lineColor: AppDesign.primaryColor.toARGB32(), lineCap: LineCap.ROUND, lineJoin: LineJoin.ROUND));
      final bottomPadding = _minBottomSheetHeight + MediaQuery.of(context).padding.bottom + 20;
      await _zoomToRoute(route, bottomPadding: bottomPadding);
      // UI'ı güncelle
      if (mounted) setState(() {});
      debugPrint('✅ Rota çizildi');
    } catch (e) {
      debugPrint('❌ Rota çizme hatası: $e');
    }
  }

  Future<void> _drawMultipleRoutes(List<directions.Route> routes) async {
    if (_mapboxMap == null || routes.isEmpty) return;
    try {
      await _clearAllRoutes();

      // Önce seçili olmayan rotaları çiz (gri), sonra seçili rotayı çiz (mavi) - böylece seçili rota üstte kalır
      for (int i = 0; i < routes.length; i++) {
        final route = routes[i];
        final isSelected = i == _selectedRouteIndex;

        // Seçili olmayan rotaları önce çiz
        if (!isSelected) {
          await _drawSingleRoute(route, i, isSelected);
        }
      }

      // Seçili rotayı en son çiz (üstte kalması için)
      if (_selectedRouteIndex < routes.length) {
        final selectedRoute = routes[_selectedRouteIndex];
        await _drawSingleRoute(selectedRoute, _selectedRouteIndex, true);
      }

      final bottomPadding = MediaQuery.of(context).size.height * 0.4 + 20;
      await _zoomToAllRoutes(routes, bottomPadding: bottomPadding);
      debugPrint('✅ Tüm rotalar çizildi (${routes.length} rota)');
    } catch (e) {
      debugPrint('❌ Çoklu rota çizme hatası: $e');
    }
  }

  Future<void> _drawSingleRoute(directions.Route route, int index, bool isSelected) async {
    final coordinates = route.geometry.map((c) => [c[0], c[1]]).toList();
    final geoJson = {'type': 'Feature', 'geometry': {'type': 'LineString', 'coordinates': coordinates}};

    final sourceId = 'route-preview-source-$index';
    final shadowLayerId = 'route-preview-shadow-$index';
    final lineLayerId = 'route-preview-line-$index';

    await _mapboxMap!.style.addSource(GeoJsonSource(id: sourceId, data: json.encode(geoJson)));

    // Gölge layer (tüm rotalar için)
    await _mapboxMap!.style.addLayer(LineLayer(
      id: shadowLayerId,
      sourceId: sourceId,
      lineWidth: isSelected ? 10.0 : 6.0,
      lineColor: Colors.black.withOpacity(isSelected ? 0.25 : 0.15).toARGB32(),
      lineBlur: 4.0
    ));

    // Ana rota çizgisi - seçili rota mavi, diğerleri gri
    await _mapboxMap!.style.addLayer(LineLayer(
      id: lineLayerId,
      sourceId: sourceId,
      lineWidth: isSelected ? 8.0 : 5.0,
      lineColor: isSelected ? AppDesign.primaryColor.toARGB32() : Colors.grey.shade500.toARGB32(),
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND
    ));
  }

  Future<void> _clearAllRoutes() async {
    if (_mapboxMap == null) return;
    try {
      // Seçili rota layer'larını temizle (eski yapı için)
      await _mapboxMap!.style.removeStyleLayer('route-preview-line-selected').catchError((_) {});
      await _mapboxMap!.style.removeStyleLayer('route-preview-shadow-selected').catchError((_) {});
      await _mapboxMap!.style.removeStyleSource('route-preview-source-selected').catchError((_) {});

      // Çoklu rota layer'larını temizle (yeni yapı)
      // Maksimum 10 rota olduğunu varsayarak temizle
      for (int i = 0; i < 10; i++) {
        await _mapboxMap!.style.removeStyleLayer('route-preview-line-$i').catchError((_) {});
        await _mapboxMap!.style.removeStyleLayer('route-preview-shadow-$i').catchError((_) {});
        await _mapboxMap!.style.removeStyleSource('route-preview-source-$i').catchError((_) {});
      }

      await _mapboxMap!.style.removeStyleLayer('route-line').catchError((_) {});
      await _mapboxMap!.style.removeStyleLayer('route-line-shadow').catchError((_) {});
      await _mapboxMap!.style.removeStyleSource('route-source').catchError((_) {});
    } catch (e) {
      // Errors are expected if layers don't exist
    }
  }

  void _resetRouteState() {
    setState(() {
      _currentRoute = null;
      _isRouteActive = false;
      _isInRoutePreview = false;
      _availableRoutes = [];
      _selectedRouteIndex = 0;
      _fuelDataCache.clear(); // Cache'i temizle
    });
  }

  void _logTollInfo(List<directions.Route> routes) {
    debugPrint('\n🚧 ===== GİŞE BİLGİLERİ =====');
    for (int i = 0; i < routes.length; i++) {
      final route = routes[i];
      if (route.tollCost != null && route.tollCost! > 0) {
        debugPrint('\n📍 ROTA ${i + 1} - ${route.routeType == directions.RouteType.fast ? "En Hızlı" : route.routeType == directions.RouteType.tollFree ? "Gişesiz" : "Alternatif"}');
        debugPrint('💰 Toplam Gişe Ücreti: ₺${route.tollCost!.toStringAsFixed(2)}');
        debugPrint('📏 Rota Mesafesi: ${route.distanceText}');
        debugPrint('⏱️ Rota Süresi: ${route.durationText}');
        
        // Rota üzerindeki gişe noktalarını listele
        final tollBooths = <String>[];
        for (final leg in route.legs) {
          for (final step in leg.steps) {
            for (final intersection in step.intersections) {
              if (intersection.tollCollection != null) {
                final tollName = intersection.tollCollection!.name;
                if (tollName.isNotEmpty && !tollBooths.contains(tollName)) {
                  tollBooths.add(tollName);
                }
              }
            }
          }
        }
        
        if (tollBooths.isNotEmpty) {
          debugPrint('🚦 Geçilecek Gişeler:');
          for (int j = 0; j < tollBooths.length; j++) {
            debugPrint('   ${j + 1}. ${tollBooths[j]}');
          }
        }
        
        // Rota üzerindeki gişe noktalarını tahmin et (geometri üzerinden)
        if (route.geometry.isNotEmpty) {
          debugPrint('📌 Rota Koordinatları: ${route.geometry.length} nokta');
          debugPrint('🎯 Başlangıç: [${route.geometry.first[1].toStringAsFixed(4)}, ${route.geometry.first[0].toStringAsFixed(4)}]');
          debugPrint('🏁 Bitiş: [${route.geometry.last[1].toStringAsFixed(4)}, ${route.geometry.last[0].toStringAsFixed(4)}]');
        }
      } else {
        debugPrint('\n📍 ROTA ${i + 1} - ${route.routeType == directions.RouteType.fast ? "En Hızlı" : route.routeType == directions.RouteType.tollFree ? "Gişesiz" : "Alternatif"}');
        debugPrint('✅ Gişe Yok - Ücretsiz Rota');
      }
    }
    debugPrint('🚧 ===========================\n');
  }

  Future<void> _zoomToRoute(directions.Route route, {double bottomPadding = 200}) async {
    if (_mapboxMap == null || route.geometry.isEmpty) return;
    try {
      final List<Point> coordinates = route.geometry
          .map((c) => Point(coordinates: Position(c[0], c[1])))
          .toList();
      
      // HATA DÜZELTME: cameraForCoordinates doğrudan Point listesi bekliyor.
      // toJson() çağrısını kaldırıyoruz.
      // ignore: deprecated_member_use
      final cameraOptions = await _mapboxMap!.cameraForCoordinates(
        coordinates, // Doğrudan Point listesini gönder
        MbxEdgeInsets(top: 150.0, left: 40.0, bottom: bottomPadding, right: 40.0),
        0, // bearing
        0  // pitch
      );
      _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
    } catch(e) {
      debugPrint('❌ Rota zoom hatası: $e');
    }
  }

  Future<void> _zoomToAllRoutes(List<directions.Route> routes, {double bottomPadding = 400}) async {
    if (_mapboxMap == null || routes.isEmpty) return;
    try {
      List<Point> allPoints = [];
      for (var route in routes) {
        allPoints.addAll(route.geometry.map((c) => Point(coordinates: Position(c[0], c[1]))));
      }

      // HATA DÜZELTME: cameraForCoordinates doğrudan Point listesi bekliyor.
      // toJson() çağrısını kaldırıyoruz.
      // ignore: deprecated_member_use
      final cameraOptions = await _mapboxMap!.cameraForCoordinates(
        allPoints, // Doğrudan Point listesini gönder
        MbxEdgeInsets(top: 150.0, left: 40.0, bottom: bottomPadding, right: 40.0),
        0, // bearing
        0  // pitch
      );
      _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
    } catch(e) {
      debugPrint('❌ Tüm rotalar zoom hatası: $e');
    }
  }

  Future<void> _animatedZoomToLocation(double lat, double lng) async {
    if (_mapboxMap == null) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showUI = true);
    await _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.0),
      MapAnimationOptions(duration: 3500),
    );
  }

  Future<void> _moveToLocationFast(double lat, double lng) async {
    if (_mapboxMap == null) return;
    await _mapboxMap!.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.0),
      MapAnimationOptions(duration: 500),
    );
  }

  Widget _buildBottomSheet(BuildContext context, MapState state) {
    if (_isInRoutePreview && _availableRoutes.isNotEmpty) {
      return _buildRoutePreviewContent();
    }
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final delta = -details.delta.dy;
        final dragRange = _maxBottomSheetHeight - _minBottomSheetHeight;
        if (dragRange > 0) {
          setState(() {
            _bottomSheetPosition = (_bottomSheetPosition + delta / dragRange).clamp(0.0, 1.0);
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy.abs() > 500) {
          details.velocity.pixelsPerSecond.dy < 0 ? _openBottomSheet() : _closeBottomSheet();
        } else {
          _bottomSheetPosition > 0.5 ? _openBottomSheet() : _closeBottomSheet();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: _minBottomSheetHeight + (_maxBottomSheetHeight - _minBottomSheetHeight) * _bottomSheetPosition,
        decoration: BoxDecoration(
          color: AppDesign.backgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppDesign.panelRadius), topRight: Radius.circular(AppDesign.panelRadius)),
          boxShadow: AppDesign.panelShadow,
        ),
        child: Column(
          children: [const PanelHandle(), Expanded(child: _buildBottomSheetContent())],
        ),
      ),
    );
  }

  void _openBottomSheet() {
    _bottomSheetController.forward(from: _bottomSheetPosition);
    setState(() => _bottomSheetPosition = 1.0);
  }

  void _closeBottomSheet() {
    _bottomSheetController.reverse(from: _bottomSheetPosition);
    setState(() => _bottomSheetPosition = 0.0);
  }

  Widget _buildBottomSheetContent() {
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final contentBottomPadding = _contentSafeZone - systemBottomPadding;
    final isExpanded = _bottomSheetPosition > 0.3;
    return SingleChildScrollView(
      physics: isExpanded ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(left: AppDesign.panelPadding, right: AppDesign.panelPadding, top: 12, bottom: contentBottomPadding > 0 ? contentBottomPadding : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveRouteInfo(),
          _buildSearchAndProfileSection(),
          const SizedBox(height: 24),
          _buildSmartAnimatedContent(
            requiredHeight: 300.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kaydedilenler bölümü
                if (_savedPlaces.isEmpty) ...[
                  // Boş durum - büyük + butonu ile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Column(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppDesign.primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kaydedilenler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppDesign.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () => _showAddSavedPlacePanel(),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppDesign.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppDesign.primaryColor.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppDesign.primaryColor,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Yeni yer ekle',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppDesign.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Dolu durum - modern kart tasarımı
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppDesign.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kaydedilenler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppDesign.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: AppDesign.primaryColor, size: 28),
                              onPressed: () => _showAddSavedPlacePanel(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Gruplanmış kartlar
                        ..._buildGroupedSavedPlaces(),
                      ],
                    ),
                  ),
                ],

                // Son Aramalar bölümü
                if (_recentSearches.isNotEmpty) ...[
                  const Text('Son Aramalar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppDesign.textPrimary)),
                  const SizedBox(height: 16),
                  ..._recentSearches.map((search) => GestureDetector(
                    onTap: () {
                      // Arama ekranına git ve bu yeri seç
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchAndRouteScreen()),
                      ).then((result) {
                        if (result != null && result is Map<String, dynamic> && mounted) {
                          final routes = result['routes'] as List<directions.Route>?;
                          final origin = result['origin'] as GeocodingResult?;
                          final destination = result['destination'] as GeocodingResult?;
                          
                          if (routes != null && routes.isNotEmpty) {
                            _logTollInfo(routes); // Gişe bilgilerini logla
                            setState(() {
                              _availableRoutes = routes;
                              _selectedRouteIndex = 0;
                              _isInRoutePreview = true;
                              _origin = origin;
                              _destination = destination;
                            });
                            _drawMultipleRoutes(routes);
                          }
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppDesign.overlayColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppDesign.dividerColor)
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: AppDesign.iconColor, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  search.placeName,
                                  style: const TextStyle(fontSize: 15, color: AppDesign.textPrimary, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (search.address != null && search.address!.isNotEmpty)
                                  Text(
                                    search.address!,
                                    style: TextStyle(fontSize: 13, color: AppDesign.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: AppDesign.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRouteInfo() {
    if (!_isRouteActive || _currentRoute == null) return const SizedBox.shrink();
    
    final bool hasTollCost = (_currentRoute!.tollCost ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppDesign.primaryColor, AppDesign.primaryColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppDesign.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.navigation, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Rota Bilgisi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await _clearAllRoutes();
                  _resetRouteState();
                  if (mounted) NotificationHelper.show(context, 'Rota temizlendi');
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
              GestureDetector(
                onTap: () => _showTripRecordingDialog(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRouteMetric('Mesafe', _currentRoute!.distanceText, Icons.straighten, isSelected: true)),
              _buildDivider(true),
              Expanded(child: _buildRouteMetric('Süre', _currentRoute!.durationText, Icons.access_time, isSelected: true)),
              if (hasTollCost) ...[
                _buildDivider(true),
                Expanded(child: _buildRouteMetric('Gişe', '₺${_currentRoute!.tollCost!.toStringAsFixed(0)}', Icons.money_rounded, isSelected: true)),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndProfileSection() {
    // ignore_for_file: use_build_context_synchronously
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey.shade50]),
        boxShadow: [BoxShadow(color: AppDesign.primaryColor.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4)), BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: SearchBarWidget(
                hintText: 'Konum girin',
                onTap: () async {
                  geo.Position? userGeolocatorPosition;
                  if (_userLocationPoint != null) {
                    userGeolocatorPosition = geo.Position(
                      longitude: _userLocationPoint!.coordinates.lng.toDouble(),
                      latitude: _userLocationPoint!.coordinates.lat.toDouble(),
                      timestamp: DateTime.now(),
                      accuracy: 0.0,
                      altitude: 0.0,
                      altitudeAccuracy: 0.0,
                      heading: 0.0,
                      headingAccuracy: 0.0,
                      speed: 0.0,
                      speedAccuracy: 0.0,
                    );
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchAndRouteScreen(userLocation: userGeolocatorPosition)),
                  );
                  if (result != null && result is Map<String, dynamic> && mounted) {
                    final routes = result['routes'] as List<directions.Route>?;
                    final origin = result['origin'] as GeocodingResult?;
                    final destination = result['destination'] as GeocodingResult?;
                    
                    if (routes != null && routes.isNotEmpty) {
                      _logTollInfo(routes); // Gişe bilgilerini logla
                      setState(() {
                        _availableRoutes = routes;
                        _selectedRouteIndex = 0;
                        _isInRoutePreview = true;
                        _origin = origin;
                        _destination = destination;
                      });
                      await _drawMultipleRoutes(routes);
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            UserAvatar(initials: _getInitials(_currentUser?.displayName ?? 'U'), onTap: _openProfilePanel),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSmartAnimatedContent({required double requiredHeight, required Widget child}) {
    final currentHeight = _minBottomSheetHeight + (_maxBottomSheetHeight - _minBottomSheetHeight) * _bottomSheetPosition;
    final progress = ((currentHeight - _minBottomSheetHeight) / requiredHeight).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: progress,
      duration: AppDesign.fastAnimation,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: Offset(0, 0.15 * (1 - progress)),
        duration: AppDesign.fastAnimation,
        curve: Curves.easeOut,
        child: progress > 0.05 ? child : const SizedBox.shrink(),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _searchHistoryService.getSearchHistory();
    if (mounted) {
      setState(() {
        _recentSearches = searches.take(3).toList(); // Son 3 arama
      });
    }
  }

  Future<void> _loadSavedPlaces() async {
    final places = await _savedPlacesService.getSavedPlaces();
    if (mounted) {
      setState(() {
        _savedPlaces = places.take(5).toList(); // İlk 5 kaydedilen yer
      });
      // Haritada marker'ları güncelle
      await _updateSavedPlacesMarkers();
    }
  }

  Future<void> _showAddSavedPlacePanel() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSavedPlacePanel(),
    ).then((result) {
      if (result != null && result is GeocodingResult && mounted) {
        _showAddSavedPlaceDialog(result);
      }
    });
  }

  Future<void> _showSavedPlaceOptionsDialog(SavedPlace place) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Düzenle'),
            onTap: () {
              Navigator.of(context).pop();
              _showEditSavedPlaceDialog(place);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Sil', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _showDeleteConfirmationDialog(place);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSavedPlaceDialog(GeocodingResult location) async {
    String placeName = location.placeName;
    String selectedIcon = 'star';
    Color selectedColor = AppDesign.primaryColor;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeri Kaydet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Yer Adı',
                    hintText: 'Örn: Ev, İş, Okul',
                  ),
                  controller: TextEditingController(text: placeName),
                  onChanged: (value) => placeName = value,
                ),
                const SizedBox(height: 24),
                const Text('İkon Seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: SavedPlace.suggestedIcons.take(20).map((iconName) {
                    final isSelected = selectedIcon == iconName;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = iconName),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            SavedPlace(iconName: iconName, id: '', name: '', location: location, savedAt: DateTime.now()).icon,
                            color: isSelected ? (selectedColor == AppDesign.primaryColor ? Colors.grey : selectedColor) : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Renk Seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: SavedPlace.suggestedColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (placeName.trim().isEmpty) return;

                final newPlace = SavedPlace(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: placeName.trim(),
                  location: location,
                  iconName: selectedIcon,
                  savedAt: DateTime.now(),
                  customColor: selectedColor,
                );

                await _savedPlacesService.savePlace(newPlace);
                await _loadSavedPlaces();

                if (mounted) {
                  Navigator.of(context).pop();
                  NotificationHelper.show(context, 'Yer kaydedildi');
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSavedPlaces() {
    // Yerleri ikonlarına göre grupla
    final groupedPlaces = <String, List<SavedPlace>>{};
    for (final place in _savedPlaces) {
      final key = place.iconName;
      if (!groupedPlaces.containsKey(key)) {
        groupedPlaces[key] = [];
      }
      groupedPlaces[key]!.add(place);
    }

    final widgets = <Widget>[];

    // Her grup için yuvarlak kartlar oluştur
    for (final entry in groupedPlaces.entries) {
      final places = entry.value;

      if (places.length == 1) {
        // Tek yer varsa normal kart
        final place = places.first;
        widgets.add(_buildSavedPlaceCard(place));
      } else {
        // Birden fazla yer varsa yuvarlak kartlar
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grup başlığı
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: places.first.customColor?.withOpacity(0.1) ?? AppDesign.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            places.first.icon,
                            color: places.first.customColor ?? AppDesign.primaryColor,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${places.length} yer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppDesign.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Yuvarlak kartlar
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final place = places[index];
                      return Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        child: _buildCircularSavedPlaceCard(place),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildSavedPlaceCard(SavedPlace place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppDesign.overlayColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Bu yeri hedef olarak seç ve rota ekranına git
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchAndRouteScreen()),
            ).then((result) {
              if (result != null && result is Map<String, dynamic> && mounted) {
                final routes = result['routes'] as List<directions.Route>?;
                final origin = result['origin'] as GeocodingResult?;
                final destination = result['destination'] as GeocodingResult?;
                
                if (routes != null && routes.isNotEmpty) {
                  _logTollInfo(routes); // Gişe bilgilerini logla
                  setState(() {
                    _availableRoutes = routes;
                    _selectedRouteIndex = 0;
                    _isInRoutePreview = true;
                    _origin = origin;
                    _destination = destination;
                  });
                  _drawMultipleRoutes(routes);
                }
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: place.customColor ?? AppDesign.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          place.icon,
                          color: place.iconColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppDesign.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            place.location.placeName,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppDesign.textSecondary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Silme butonu
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmationDialog(place),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }  Widget _buildCircularSavedPlaceCard(SavedPlace place) {
    return GestureDetector(
      onTap: () {
        // Bu yeri hedef olarak seç ve rota ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchAndRouteScreen()),
        ).then((result) {
          if (result != null && result is Map<String, dynamic> && mounted) {
            final routes = result['routes'] as List<directions.Route>?;
            final origin = result['origin'] as GeocodingResult?;
            final destination = result['destination'] as GeocodingResult?;
            
            if (routes != null && routes.isNotEmpty) {
              _logTollInfo(routes); // Gişe bilgilerini logla
              setState(() {
                _availableRoutes = routes;
                _selectedRouteIndex = 0;
                _isInRoutePreview = true;
                _origin = origin;
                _destination = destination;
              });
              _drawMultipleRoutes(routes);
            }
          }
        });
      },
      onLongPress: () => _showSavedPlaceOptionsDialog(place),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: place.customColor ?? AppDesign.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: place.customColor ?? AppDesign.primaryColor.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    place.icon,
                    color: place.iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                height: 16,
                child: Text(
                  place.name,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppDesign.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Silme butonu
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: () => _showDeleteConfirmationDialog(place),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }  Future<void> _showEditSavedPlaceDialog(SavedPlace place) async {
    String placeName = place.name;
    String selectedIcon = place.iconName;
    Color selectedColor = place.customColor ?? AppDesign.primaryColor;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeri Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Yer Adı',
                    hintText: 'Örn: Ev, İş, Okul',
                  ),
                  controller: TextEditingController(text: placeName),
                  onChanged: (value) => placeName = value,
                ),
                const SizedBox(height: 24),
                const Text('İkon Seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: SavedPlace.suggestedIcons.take(20).map((iconName) {
                    final isSelected = selectedIcon == iconName;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = iconName),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            SavedPlace(iconName: iconName, id: '', name: '', location: place.location, savedAt: DateTime.now()).icon,
                            color: isSelected ? (selectedColor == AppDesign.primaryColor ? Colors.grey : SavedPlace(iconName: iconName, id: '', name: '', location: place.location, savedAt: DateTime.now(), customColor: selectedColor).iconColor) : Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Renk Seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: SavedPlace.suggestedColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (placeName.trim().isEmpty) return;

                final updatedPlace = SavedPlace(
                  id: place.id,
                  name: placeName.trim(),
                  location: place.location,
                  iconName: selectedIcon,
                  savedAt: place.savedAt,
                  customColor: selectedColor,
                );

                await _savedPlacesService.updatePlace(updatedPlace);
                await _loadSavedPlaces();

                if (mounted) {
                  Navigator.of(context).pop();
                  NotificationHelper.show(context, 'Yer güncellendi');
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(SavedPlace place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeri Sil'),
        content: Text('"${place.name}" adlı yeri silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _savedPlacesService.deletePlace(place.id);
      await _loadSavedPlaces();

      if (mounted) {
        NotificationHelper.show(context, 'Yer silindi');
      }
    }
  }


  
  Widget _buildRoutePreviewContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.backgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppDesign.panelRadius), topRight: Radius.circular(AppDesign.panelRadius)),
        boxShadow: AppDesign.panelShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PanelHandle(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await _clearAllRoutes();
                      _resetRouteState();
                      // Kullanıcı konumuna zoom yap
                      if (_userLocationPoint != null) {
                        await _moveToLocationFast(
                          _userLocationPoint!.coordinates.lat.toDouble(),
                          _userLocationPoint!.coordinates.lng.toDouble(),
                        );
                      }
                      // Konum butonunu göster
                      if (mounted) {
                        setState(() {
                          _showLocationButton = true;
                        });
                        // Kısa bir süre sonra konum butonunu gizle (kullanıcı konumundayız)
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (mounted) {
                          setState(() {
                            _showLocationButton = false;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Icon(Icons.close, size: 20, color: AppDesign.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rota Seçin',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppDesign.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220, // Daha fazla yükseklik için daha iyi görünüm
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableRoutes.length,
                itemBuilder: (context, index) {
                  final route = _availableRoutes[index];
                  final isSelected = _selectedRouteIndex == index;

                  String title;
                  switch (route.routeType) {
                    case directions.RouteType.fast:
                      title = 'En Hızlı Rota';
                      break;
                    case directions.RouteType.tollFree:
                      title = 'Gişesiz Rota';
                      break;
                    case directions.RouteType.city:
                      title = 'Alternatif Rota';
                      break;
                    default:
                      title = 'Rota ${index + 1}';
                      break;
                  }

                  IconData icon;
                  switch (route.routeType) {
                    case directions.RouteType.fast:
                      icon = Icons.speed;
                      break;
                    case directions.RouteType.tollFree:
                      icon = Icons.toll;
                      break;
                    case directions.RouteType.city:
                      icon = Icons.alt_route;
                      break;
                    default:
                      icon = Icons.directions_car;
                      break;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    margin: EdgeInsets.only(bottom: index < _availableRoutes.length - 1 ? 16 : 0),
                    transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (isSelected) {
                            // Zaten seçili ise detayları göster
                            _showRouteDetailsDialog(route, index);
                          } else {
                            // Seçili değilse sadece seç ve haritada göster
                            setState(() => _selectedRouteIndex = index);
                            await _drawMultipleRoutes(_availableRoutes);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? AppDesign.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppDesign.primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? AppDesign.primaryColor.withOpacity(0.2) 
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: isSelected ? 12 : 8,
                                offset: Offset(0, isSelected ? 4 : 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Colors.white.withOpacity(0.2)
                                          : AppDesign.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isSelected ? Colors.white : AppDesign.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? Colors.white : AppDesign.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Seçildi',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              FutureBuilder<Map<String, double>>(
                                future: _calculateFuelDataForRoute(route, index),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Maliyet hesaplanıyor...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final fuelData = snapshot.data ?? {'cost': 0.0, 'liters': 0.0};
                                  final fuelCost = fuelData['cost']!;
                                  final hasFuelCost = fuelCost > 0.01;
                                  final bool hasTollCost = (route.tollCost ?? 0) > 0;

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Colors.white.withOpacity(0.15)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildModernRouteMetric(
                                            'Mesafe',
                                            route.distanceText,
                                            Icons.straighten,
                                            isSelected: isSelected,
                                          ),
                                        ),
                                        Container(
                                          height: 28,
                                          width: 1,
                                          color: isSelected 
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.grey.shade300,
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                        Expanded(
                                          child: _buildModernRouteMetric(
                                            'Süre',
                                            route.durationText,
                                            Icons.access_time,
                                            isSelected: isSelected,
                                          ),
                                        ),
                                        if (hasFuelCost) ...[
                                          Container(
                                            height: 28,
                                            width: 1,
                                            color: isSelected 
                                                ? Colors.white.withOpacity(0.3)
                                                : Colors.grey.shade300,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          Expanded(
                                            child: _buildModernRouteMetric(
                                              'Maliyet',
                                              '₺${fuelCost.toStringAsFixed(0)}',
                                              Icons.local_gas_station,
                                              isSelected: isSelected,
                                            ),
                                          ),
                                        ],
                                        if (hasTollCost) ...[
                                          Container(
                                            height: 28,
                                            width: 1,
                                            color: isSelected 
                                                ? Colors.white.withOpacity(0.3)
                                                : Colors.grey.shade300,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          Expanded(
                                            child: _buildModernRouteMetric(
                                              'Gişe',
                                              '₺${route.tollCost!.toStringAsFixed(0)}',
                                              Icons.toll,
                                              isSelected: isSelected,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Doğrudan rotayı 5 parçaya böl ve navigasyonu başlat
                    final selectedRoute = _availableRoutes[_selectedRouteIndex];

                    try {
                      // Kullanıcı giriş yapmış mı kontrol et
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      String? tripId;
                      Vehicle? defaultVehicle;

                      // Eğer kullanıcı giriş yapmışsa varsayılan aracı al ve trip başlat
                      if (userId != null) {
                        defaultVehicle = await _fuelCostService.getDefaultVehicle(userId);

                        if (defaultVehicle != null) {
                          tripId = await _tripService.startTrip(
                            userId: userId,
                            vehicleId: defaultVehicle.id,
                            startLat: _origin?.latitude ?? 0.0,
                            startLng: _origin?.longitude ?? 0.0,
                            endLat: _destination?.latitude ?? 0.0,
                            endLng: _destination?.longitude ?? 0.0,
                            estimatedDistanceKm: selectedRoute.distance / 1000.0,
                          );
                        }
                      }

                      // Rotayı aktif et
                      if (mounted) {
                        setState(() {
                          _currentRoute = selectedRoute;
                          _currentTripId = tripId;
                          _isRouteActive = true;
                          _isInRoutePreview = false;
                          _availableRoutes = [];
                        });
                        await _drawRoute(selectedRoute);
                      }

                      // Rotayı segmentlere böl ve navigasyonu başlat
                      await _segmentRouteAndLaunchNavigation(selectedRoute);

                      // Google Maps'e gönderildikten sonra ekranı temizle
                      if (mounted) {
                        await _clearAllRoutes();
                        _resetRouteState();
                        NotificationHelper.show(context, 'Google Maps\'te yönlendiriliyor');
                      }
                    } catch (e) {
                      if (mounted) {
                        NotificationHelper.show(context, 'Rota başlatılırken hata: $e', isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesign.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    shadowColor: AppDesign.primaryColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Başla',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, double>> _calculateFuelDataForRoute(directions.Route route, int routeIndex) async {
    // Cache kontrolü - eğer daha önce hesaplanmışsa cache'den döndür
    if (_fuelDataCache.containsKey(routeIndex)) {
      return _fuelDataCache[routeIndex]!;
    }

    try {
      // Kullanıcı giriş yapmış mı kontrol et
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        return {'cost': 0.0, 'liters': 0.0};
      }

      // Varsayılan aracı al
      final defaultVehicle = await _fuelCostService.getDefaultVehicle(userId);
      if (defaultVehicle == null) {
        return {'cost': 0.0, 'liters': 0.0};
      }

      // Mesafeyi km'ye çevir
      final distanceKm = route.distance / 1000.0;

      // Trafik seviyesini hesapla
      final trafficLevel = _calculateTrafficLevelForRoute(route);
      final averageSpeed = _calculateAverageSpeedForRoute(route);

      // Elevation verilerini al
      final elevationService = ElevationService();
      final elevations = await elevationService.getElevationsAlongRoute(route.geometry);
      final averageSlope = elevationService.calculateAverageSlope(elevations);

      // Yakıt verilerini hesapla
      final fuelData = await _fuelCostService.calculateFuelData(
        distanceKm: distanceKm,
        vehicle: defaultVehicle,
        trafficLevel: trafficLevel,
        averageSpeed: averageSpeed,
        averageSlope: averageSlope,
      );

      // Cache'e kaydet
      _fuelDataCache[routeIndex] = fuelData;
      
      return fuelData;
    } catch (e) {
      debugPrint('💥 Yakıt verileri hesaplama hatası: $e');
      return {'cost': 0.0, 'liters': 0.0};
    }
  }

  int _calculateTrafficLevelForRoute(directions.Route route) {
    if (route.congestion == null || route.congestion!.isEmpty) {
      return 0; // Bilinmiyor = düşük trafik
    }

    final congestionData = route.congestion!;
    final totalSegments = congestionData.length;
    if (totalSegments == 0) return 0;

    // Congestion seviyelerini say
    int lowCount = 0;
    int moderateCount = 0;
    int heavyCount = 0;
    int severeCount = 0;

    for (final level in congestionData) {
      switch (level.toLowerCase()) {
        case 'low':
          lowCount++;
          break;
        case 'moderate':
          moderateCount++;
          break;
        case 'heavy':
          heavyCount++;
          break;
        case 'severe':
          severeCount++;
          break;
      }
    }

    // En yaygın congestion seviyesine göre trafik seviyesi döndür (0-10 arası)
    final maxCount = [lowCount, moderateCount, heavyCount, severeCount].reduce((a, b) => a > b ? a : b);

    if (severeCount == maxCount && severeCount > 0) return 9; // Çok yoğun
    if (heavyCount == maxCount && heavyCount > 0) return 7; // Yoğun
    if (moderateCount == maxCount && moderateCount > 0) return 5; // Orta
    if (lowCount == maxCount && lowCount > 0) return 2; // Hafif

    return 0; // Bilinmiyor
  }

  double? _calculateAverageSpeedForRoute(directions.Route route) {
    if (route.distance <= 0 || route.duration <= 0) {
      return null;
    }

    // Ortalama hız = mesafe / süre (km/h)
    final distanceKm = route.distance / 1000.0;
    final durationHours = route.duration / 3600.0; // saniyeden saate çevir

    if (durationHours <= 0) return null;

    return distanceKm / durationHours;
  }

  void _showRouteDetailsDialog(directions.Route route, int routeIndex) {
    showDialog(
      context: context,
      builder: (context) => RouteDetailsDialog(
        route: route,
        routeIndex: routeIndex,
        origin: _origin,
        destination: _destination,
        fuelCostService: _fuelCostService,
        fuelDataCache: _fuelDataCache[routeIndex], // Cache'den gönder
      ),
    );
  }

  Future<void> _updateSavedPlacesMarkers() async {
    if (_mapboxMap == null) return;

    try {
      // Önceki marker'ları temizle
      await _clearSavedPlacesMarkers();

      if (_savedPlaces.isEmpty) return;

      // Her kaydedilen yer için marker ekle
      for (final place in _savedPlaces) {
        // Symbol layer için geojson oluştur
        final geoJson = {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [place.location.longitude, place.location.latitude]
          },
          'properties': {
            'id': place.id,
            'name': place.name,
            'icon': place.iconName,
          }
        };

        // Kaydedilen yer için benzersiz layer ID
        final layerId = 'saved-place-${place.id}';
        final sourceId = 'saved-place-source-${place.id}';

        // GeoJSON source ekle
        await _mapboxMap!.style.addSource(GeoJsonSource(id: sourceId, data: json.encode(geoJson)));

        // Circle layer kullanarak yuvarlak marker oluştur
        await _mapboxMap!.style.addLayer(CircleLayer(
          id: layerId,
          sourceId: sourceId,
          circleRadius: 12.0,
          circleColor: place.customColor?.toARGB32() ?? AppDesign.primaryColor.toARGB32(),
          circleStrokeWidth: 3.0,
          circleStrokeColor: Colors.white.toARGB32(),
        ));

        debugPrint('✅ ${place.name} marker\'ı eklendi (circle)');
      }

      debugPrint('✅ ${_savedPlaces.length} kaydedilen yer marker\'ı eklendi');
    } catch (e) {
      debugPrint('❌ Kaydedilen yer marker\'ları eklenirken hata: $e');
    }
  }

  Future<void> _clearSavedPlacesMarkers() async {
    if (_mapboxMap == null) return;

    try {
      // Tüm kaydedilen yer marker'larını temizle
      for (final place in _savedPlaces) {
        final layerId = 'saved-place-${place.id}';
        final sourceId = 'saved-place-source-${place.id}';

        await _mapboxMap!.style.removeStyleLayer(layerId).catchError((_) {});
        await _mapboxMap!.style.removeStyleSource(sourceId).catchError((_) {});
      }
      debugPrint('✅ Kaydedilen yer marker\'ları temizlendi');
    } catch (e) {
      debugPrint('Layer temizleme hatası (normal olabilir): $e');
    }
  }

  void _onMapTap(TapUpDetails details) async {
    // Şimdilik boş - marker tıklama işlevi sonra eklenecek
    debugPrint('Harita tıklandı: ${details.localPosition}');
  }

  void _onMapLongPress(LongPressStartDetails details) async {
    if (_mapboxMap == null) return;

    try {
      // Ekran koordinatlarını harita koordinatlarına çevir
      final screenCoordinate = ScreenCoordinate(x: details.localPosition.dx, y: details.localPosition.dy);
      final coordinate = await _mapboxMap!.coordinateForPixel(screenCoordinate);

      final lat = coordinate.coordinates.lat.toDouble();
      final lng = coordinate.coordinates.lng.toDouble();

      // Mapbox reverse geocoding ile cadde ismini al
      final geocodingService = GeocodingService();
      final addressResult = await geocodingService.reverseGeocode(lat: lat, lng: lng);

      // Adres bilgisi varsa onu kullan, yoksa koordinatları göster
      final placeName = addressResult?.placeName ?? 'Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      final address = addressResult?.address;

      final location = GeocodingResult(
        id: 'manual_$lat,$lng',
        placeName: placeName,
        address: address,
        latitude: lat,
        longitude: lng,
        placeType: 'manual',
      );

      // Kaydedilen yer ekleme dialogunu göster
      if (mounted) {
        await _showAddSavedPlaceDialog(location);
      }
    } catch (e) {
      debugPrint('❌ Harita uzun basma hatası: $e');
      if (mounted) {
        NotificationHelper.show(context, 'Konum tespit edilemedi', isError: true);
      }
    }
  }

  Widget _buildRouteMetric(String label, String value, IconData icon, {Color? color, bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color?.withOpacity(0.1) ?? AppDesign.overlayColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color?.withOpacity(0.3) ?? AppDesign.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppDesign.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppDesign.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? AppDesign.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRouteMetric(String label, String value, IconData icon, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppDesign.primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white.withOpacity(0.9) : AppDesign.textSecondary,
            letterSpacing: -0.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppDesign.textPrimary,
            letterSpacing: -0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isSelected) {
    return Container(
      height: 1,
      color: AppDesign.dividerColor.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  Future<void> _showTripRecordingDialog() async {
    if (_currentTripId == null || _currentRoute == null) {
      NotificationHelper.show(context, 'Aktif yolculuk bulunamadı', isError: true);
      return;
    }

    // Kullanıcının varsayılan aracını al
    final userId = FirebaseAuth.instance.currentUser?.uid;
    String vehicleName = 'Bilinmiyor';
    if (userId != null) {
      try {
        final vehicle = await _fuelCostService.getDefaultVehicle(userId);
        if (vehicle != null) {
          vehicleName = '${vehicle.brand} ${vehicle.model}';
        }
      } catch (e) {
        debugPrint('Araç bilgisi alınamadı: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (context) => TripRecordingDialog(
        tripId: _currentTripId!,
        estimatedDistance: _currentRoute!.distance / 1000.0,
        vehicleName: vehicleName,
        firestore: _firestore,
        prefs: _prefs,
      ),
    );
  }

  Future<void> _segmentRouteAndLaunchNavigation(directions.Route route) async {
    try {
      debugPrint('🚗 Navigasyon başlatılıyor...');

      // Başlangıç ve bitiş noktalarını al
      final startCoords = route.geometry.first;
      final endCoords = route.geometry.last;

      final startLat = startCoords[1]; // Mapbox'ta [lng, lat] formatında
      final startLng = startCoords[0];
      final endLat = endCoords[1];
      final endLng = endCoords[0];

      // Direkt A->B Google Maps URL'i oluştur
      final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';

      debugPrint('🗺️ Navigasyon URL: $googleMapsUrl');

      // URL'yi aç
      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Navigasyon uygulaması açıldı');
        
        if (mounted) {
          NotificationHelper.show(context, 'Google Maps\'te yönlendiriliyor');
        }
      } else {
        // Alternatif olarak web tarayıcıda aç
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Navigasyon web tarayıcıda açıldı');
      }
    } catch (e) {
      debugPrint('❌ Navigasyon başlatma hatası: $e');
      if (mounted) {
        NotificationHelper.show(context, 'Navigasyon başlatılamadı', isError: true);
      }
    }
  }

  Point get mapCenter {
    // Return current map center or default location
    return Point(coordinates: Position(32.8541, 39.9208)); // Ankara as default (lng, lat)
  }

  Future<void> _loadTripCompletionSettings() async {
    // Trip completion ayarlarını yükle (şimdilik boş)
  }

  Future<void> _checkProximityToSavedPlaces(LocationEntity userLocation) async {
    if (_savedPlaces.isEmpty) return;

    const double proximityThresholdKm = 1.0; // 1km threshold
    const Duration cooldownDuration = Duration(hours: 24); // 24 saat cooldown

    final now = DateTime.now();

    for (final place in _savedPlaces) {
      try {
        // Mesafeyi hesapla (haversine formula ile)
        final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          place.location.latitude,
          place.location.longitude,
        );

        if (distance <= proximityThresholdKm) {
          // Bu yere yakın, son gösterim zamanını kontrol et
          final lastShownKey = 'trip_completion_last_shown_${place.id}';
          final lastShownStr = _prefs.getString(lastShownKey);

          if (lastShownStr != null) {
            final lastShown = DateTime.parse(lastShownStr);
            if (now.difference(lastShown) < cooldownDuration) {
              // Henüz cooldown süresi dolmamış
              continue;
            }
          }

          // Trip completion dialog'ını göster
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => TripCompletionDialog(
                destination: place,
                firestore: _firestore,
                prefs: _prefs,
              ),
            );

            // Son gösterim zamanını kaydet
            await _prefs.setString(lastShownKey, now.toIso8601String());

            // Sadece bir dialog göster ve çık
            break;
          }
        }
      } catch (e) {
        debugPrint('❌ Proximity check hatası (${place.name}): $e');
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
             math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

class AddSavedPlacePanel extends StatefulWidget {
  const AddSavedPlacePanel({super.key});

  @override
  State<AddSavedPlacePanel> createState() => _AddSavedPlacePanelState();
}

class _AddSavedPlacePanelState extends State<AddSavedPlacePanel> {
  final TextEditingController _searchController = TextEditingController();
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    // Önceki timer'ı iptal et
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // 500ms bekle, eğer yeni arama gelmezse çalıştır
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);

      try {
        // Mapbox geocoding kullanarak arama yap
        final geocodingService = GeocodingService();
        final results = await geocodingService.search(query: query);
        final limitedResults = results.take(5).toList();

        if (mounted) {
          setState(() {
            _searchResults = limitedResults;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearching = false);
          NotificationHelper.show(context, 'Arama yapılırken hata oluştu', isError: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppDesign.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          const PanelHandle(),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Yer Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppDesign.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppDesign.textSecondary),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppDesign.overlayColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDesign.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cadde, mahalle veya yer adı ara...',
                  hintStyle: TextStyle(color: AppDesign.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppDesign.iconColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _searchPlaces(value);
                  } else {
                    setState(() => _searchResults = []);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: AppDesign.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sonuç bulunamadı',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppDesign.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppDesign.overlayColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppDesign.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: AppDesign.primaryColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                result.placeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppDesign.textPrimary,
                                ),
                              ),
                              subtitle: result.address != null && result.address!.isNotEmpty
                                  ? Text(
                                      result.address!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppDesign.textSecondary,
                                      ),
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(result),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class RouteDetailsDialog extends StatefulWidget {
  final directions.Route route;
  final int routeIndex;
  final GeocodingResult? origin;
  final GeocodingResult? destination;
  final FuelCostService fuelCostService;
  final Map<String, double>? fuelDataCache; // Önceden hesaplanmış data

  const RouteDetailsDialog({
    super.key,
    required this.route,
    required this.routeIndex,
    required this.origin,
    required this.destination,
    required this.fuelCostService,
    this.fuelDataCache,
  });

  @override
  State<RouteDetailsDialog> createState() => _RouteDetailsDialogState();
}

class _RouteDetailsDialogState extends State<RouteDetailsDialog> {
  Map<String, double>? _fuelData;
  bool _isLoadingFuel = true;
  double? _averageSlope;
  String? _trafficStatus;
  bool _isLoadingRouteData = true;

  final ElevationService _elevationService = ElevationService();

  @override
  void initState() {
    super.initState();
    // Eğer cache'de varsa direkt kullan
    if (widget.fuelDataCache != null) {
      _fuelData = widget.fuelDataCache;
      _isLoadingFuel = false;
    } else {
      _calculateFuelData();
    }
    _loadRouteData();
  }

  Future<void> _calculateFuelData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _fuelData = {'cost': 0.0, 'liters': 0.0};
          _isLoadingFuel = false;
        });
        return;
      }

      final vehicle = await widget.fuelCostService.getDefaultVehicle(userId);
      if (vehicle == null) {
        setState(() {
          _fuelData = {'cost': 0.0, 'liters': 0.0};
          _isLoadingFuel = false;
        });
        return;
      }

      // Trafik seviyesini hesapla
      final trafficLevel = _calculateTrafficLevel();
      final averageSpeed = _calculateAverageSpeed();

      // Elevation verilerini bekle (eğer henüz yüklenmemişse)
      if (_averageSlope == null) {
        await _loadRouteData();
      }

      final data = await widget.fuelCostService.calculateFuelData(
        distanceKm: widget.route.distance / 1000.0,
        vehicle: vehicle,
        trafficLevel: trafficLevel,
        averageSpeed: averageSpeed,
        averageSlope: _averageSlope,
      );
      if (mounted) {
        setState(() {
          _fuelData = data;
          _isLoadingFuel = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fuelData = {'cost': 0.0, 'liters': 0.0};
          _isLoadingFuel = false;
        });
      }
    }
  }

  Future<void> _loadRouteData() async {
    try {
      // Trafik durumunu hesapla
      final trafficStatus = _calculateTrafficStatus();
      setState(() => _trafficStatus = trafficStatus);

      // Eğim verilerini al
      final elevations = await _elevationService.getElevationsAlongRoute(widget.route.geometry);
      final averageSlope = _elevationService.calculateAverageSlope(elevations);

      if (mounted) {
        setState(() {
          _averageSlope = averageSlope;
          _isLoadingRouteData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _averageSlope = 0.0;
          _trafficStatus = 'Bilinmiyor';
          _isLoadingRouteData = false;
        });
      }
    }
  }

  String _getRouteTitle() {
    switch (widget.route.routeType) {
      case directions.RouteType.fast:
        return 'Hızlı Rota';
      case directions.RouteType.tollFree:
        return 'Ücretsiz Rota';
      case directions.RouteType.city:
        return 'Şehir İçi Rota';
      default:
        return 'Rota ${widget.routeIndex + 1}';
    }
  }

  IconData _getRouteIcon() {
    switch (widget.route.routeType) {
      case directions.RouteType.fast:
        return Icons.speed;
      case directions.RouteType.tollFree:
        return Icons.money_off;
      case directions.RouteType.city:
        return Icons.location_city;
      default:
        return Icons.directions_car;
    }
  }

  int _calculateTrafficLevel() {
    if (widget.route.congestion == null || widget.route.congestion!.isEmpty) {
      return 0; // Bilinmiyor = düşük trafik
    }

    final congestionData = widget.route.congestion!;
    final totalSegments = congestionData.length;
    if (totalSegments == 0) return 0;

    // Congestion seviyelerini say
    int lowCount = 0;
    int moderateCount = 0;
    int heavyCount = 0;
    int severeCount = 0;

    for (final level in congestionData) {
      switch (level.toLowerCase()) {
        case 'low':
          lowCount++;
          break;
        case 'moderate':
          moderateCount++;
          break;
        case 'heavy':
          heavyCount++;
          break;
        case 'severe':
          severeCount++;
          break;
      }
    }

    // En yaygın congestion seviyesine göre trafik seviyesi döndür (0-10 arası)
    final maxCount = [lowCount, moderateCount, heavyCount, severeCount].reduce((a, b) => a > b ? a : b);

    if (severeCount == maxCount && severeCount > 0) return 9; // Çok yoğun
    if (heavyCount == maxCount && heavyCount > 0) return 7; // Yoğun
    if (moderateCount == maxCount && moderateCount > 0) return 5; // Orta
    if (lowCount == maxCount && lowCount > 0) return 2; // Hafif

    return 0; // Bilinmiyor
  }

  double? _calculateAverageSpeed() {
    if (widget.route.distance <= 0 || widget.route.duration <= 0) {
      return null;
    }

    // Ortalama hız = mesafe / süre (km/h)
    final distanceKm = widget.route.distance / 1000.0;
    final durationHours = widget.route.duration / 3600.0; // saniyeden saate çevir

    if (durationHours <= 0) return null;

    return distanceKm / durationHours;
  }

  String _calculateTrafficStatus() {
    if (widget.route.congestion == null || widget.route.congestion!.isEmpty) {
      return 'Bilinmiyor';
    }

    final congestionData = widget.route.congestion!;
    final totalSegments = congestionData.length;
    if (totalSegments == 0) return 'Bilinmiyor';

    // Congestion seviyelerini say
    int lowCount = 0;
    int moderateCount = 0;
    int heavyCount = 0;
    int severeCount = 0;

    for (final level in congestionData) {
      switch (level.toLowerCase()) {
        case 'low':
          lowCount++;
          break;
        case 'moderate':
          moderateCount++;
          break;
        case 'heavy':
          heavyCount++;
          break;
        case 'severe':
          severeCount++;
          break;
      }
    }

    // En yaygın congestion seviyesini bul
    final maxCount = [lowCount, moderateCount, heavyCount, severeCount].reduce((a, b) => a > b ? a : b);

    if (severeCount == maxCount && severeCount > 0) return 'Çok Yoğun';
    if (heavyCount == maxCount && heavyCount > 0) return 'Yoğun';
    if (moderateCount == maxCount && moderateCount > 0) return 'Orta';
    if (lowCount == maxCount && lowCount > 0) return 'Akıcı';

    return 'Bilinmiyor';
  }

  Color _getTrafficColor() {
    switch (_trafficStatus) {
      case 'Akıcı':
        return Colors.green;
      case 'Orta':
        return Colors.yellow;
      case 'Yoğun':
        return Colors.orange;
      case 'Çok Yoğun':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<String> _getTollDetails() {
    if ((widget.route.tollCost ?? 0) == 0) return [];

    // Gerçek gişe isimlerini rota verisinden çıkar
    final List<String> tollNames = [];
    final Set<String> processedNames = {};

    for (final leg in widget.route.legs) {
      for (final step in leg.steps) {
        for (final intersection in step.intersections) {
          if (intersection.tollCollection != null) {
            final tollName = intersection.tollCollection!.name;
            if (tollName.isNotEmpty && !processedNames.contains(tollName)) {
              tollNames.add(tollName);
              processedNames.add(tollName);
            }
          }
        }
      }
    }

    // Eğer rota verisinden gişe bulunamazsa, boş liste döndür
    return tollNames;
  }

  bool _hasMissingTollSegments() {
    if ((widget.route.tollCost ?? 0) == 0) return false;

    // Gişe sayısı ile ücret segment sayısı karşılaştır
    final tollNames = _getTollDetails();
    if (tollNames.length < 2) return false; // En az 2 gişe olması lazım

    // Eğer gişe sayısı 2'den fazla ama ücret 0 ise eksik segment var demektir
    // Veya debug loglarından gördüğümüz gibi bazı segmentlerin ücreti bulunamadıysa
    return tollNames.length >= 2 && (widget.route.tollCost ?? 0) < 50; // Mantıklı bir eşik değeri
  }

  @override
  Widget build(BuildContext context) {
    final fuelCost = _fuelData?['cost'] ?? 0.0;
    final tollCost = widget.route.tollCost ?? 0.0;
    final totalCost = fuelCost + tollCost;
    final hasTollCost = tollCost > 0;
    final hasFuelCost = fuelCost > 0.01;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppDesign.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getRouteIcon(), color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getRouteTitle(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.origin != null && widget.destination != null)
                          Text(
                            '${widget.origin!.placeName} → ${widget.destination!.placeName}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temel bilgiler
                    _buildInfoSection(
                      'Temel Bilgiler',
                      [
                        _buildInfoRow(Icons.straighten, 'Mesafe', widget.route.distanceText),
                        _buildInfoRow(Icons.access_time, 'Tahmini Süre', widget.route.durationText),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Yol Durumu
                    _buildInfoSection(
                      'Yol Durumu',
                      [
                        _buildInfoRow(
                          Icons.terrain,
                          'Ortalama Eğim',
                          _isLoadingRouteData
                              ? 'Hesaplanıyor...'
                              : '%${_averageSlope?.toStringAsFixed(1) ?? '0.0'}',
                          subtitle: 'Yolun genel eğim oranı',
                        ),
                        _buildInfoRow(
                          Icons.traffic,
                          'Trafik Durumu',
                          _isLoadingRouteData
                              ? 'Hesaplanıyor...'
                              : (_trafficStatus ?? 'Bilinmiyor'),
                          subtitle: 'Şu anki trafik yoğunluğu',
                          valueColor: _isLoadingRouteData ? null : _getTrafficColor(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Gişe detayları
                    if (hasTollCost) ...[
                      _buildInfoSection(
                        'Gişe Bilgileri',
                        [
                          _buildInfoRow(
                            Icons.money_rounded,
                            'Gişe Ücreti',
                            '₺${tollCost.toStringAsFixed(0)}',
                          ),
                          ..._getTollDetails().map((tollName) => _buildInfoRow(
                            Icons.toll,
                            'Gişe',
                            tollName,
                            subtitle: 'Bu gişeden geçiş yapılacak',
                          )),
                          if (_hasMissingTollSegments()) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Gişe tespit edildi fakat bazı segmentlerin ücreti bulunamadı. Gerçek gişe ücreti daha yüksek olabilir, dikkat ediniz.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Yakıt maliyeti
                    if (hasFuelCost) ...[
                      _buildInfoSection(
                        'Yakıt Maliyeti',
                        _isLoadingFuel
                            ? [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryColor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Hesaplanıyor...', style: TextStyle(color: AppDesign.textSecondary)),
                                  ],
                                ),
                              ]
                            : [
                                _buildInfoRow(
                                  Icons.local_gas_station,
                                  'Yakıt Maliyeti',
                                  '₺${fuelCost.toStringAsFixed(0)}',
                                ),
                              ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Toplam maliyet
                    if (hasFuelCost || hasTollCost)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppDesign.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppDesign.primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: AppDesign.primaryColor, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Toplam Maliyet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppDesign.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₺${totalCost.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppDesign.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppDesign.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {String? subtitle, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppDesign.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppDesign.textSecondary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppDesign.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppDesign.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
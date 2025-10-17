import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/map_controls.dart';
import '../../../../core/widgets/map_layer_selector.dart';
import '../../../../core/widgets/search_bar_widget.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/widgets/custom_notification.dart';
import '../../../../core/services/directions_service.dart' as directions;
import '../../../profile/presentation/pages/profile_screen.dart';
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
  bool _hasZoomedToLocation = false; // Konuma zoom yapıldı mı?
  bool _showLocationButton = false; // Konum butonunu göster mi?
  Point? _userLocationPoint; // Kullanıcının konumu
  String _currentMapStyle = 'STANDARD'; // Şu anki harita katmanı
  User? _currentUser; // Firebase kullanıcısı
  bool _showUI = false; // UI elementlerini göster mi? (GTAV animasyonu için)
  bool _showTraffic = false; // Trafik katmanını göster mi?
  
  // Rota için
  final directions.DirectionsService _directionsService = directions.DirectionsService();
  directions.Route? _currentRoute; // Aktif rota
  Point? _routeDestination; // Hedef nokta
  bool _isRouteActive = false; // Rota aktif mi?
  
  // Bottom Sheet için
  late AnimationController _bottomSheetController;
  double _bottomSheetPosition = 0.0; // 0.0 = kapalı, 1.0 = tam açık
  final double _minBottomSheetHeight = 140.0; // Minimum yükseklik - içeriklerin tam görünmesi için artırıldı
  final double _maxBottomSheetHeight = 600.0; // Maximum yükseklik
  final double _contentSafeZone = 120.0; // İçeriklerin her zaman bu çizginin üstünde olması için

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    context.read<MapBloc>().add(const MapInitialized());
    
    // Bottom sheet animasyon controller
    _bottomSheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _bottomSheetController.dispose();
    super.dispose();
  }

  // Harita kaydırıldığında kontrol et
  void _onMapScroll(MapContentGestureContext context) {
    _checkIfUserMovedAway();
  }

  // Haritaya uzun basıldığında - Rota hesapla
  void _onMapLongPress(MapContentGestureContext context) async {
    if (_mapboxMap == null) return;
    
    // Context'den direkt coğrafi koordinatı al
    final Point tappedPoint = context.point;
    final lat = tappedPoint.coordinates.lat.toDouble();
    final lng = tappedPoint.coordinates.lng.toDouble();
    
    debugPrint('📍 Uzun basıldı: $lat, $lng');
    
    // Rota hesapla
    _calculateRoute(lat, lng);
  }

  // Kullanıcı konumdan ayrıldı mı kontrol et
  Future<void> _checkIfUserMovedAway() async {
    if (_userLocationPoint == null || _mapboxMap == null) return;
    
    final cameraState = await _mapboxMap!.getCameraState();
    final mapCenter = cameraState.center;
    
    // İki nokta arası mesafe hesapla (basit euclidean)
    final double dx = (mapCenter.coordinates.lng - _userLocationPoint!.coordinates.lng).toDouble();
    final double dy = (mapCenter.coordinates.lat - _userLocationPoint!.coordinates.lat).toDouble();
    final double distance = dx * dx + dy * dy;
    
    // Eşik değeri (yaklaşık 50 metre karşılığı)
    const double threshold = 0.0001;
    
    if (mounted) {
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
            CustomNotification.showError(
              context,
              message: state.message,
            );
          }
          
          if (state is MapLoaded && state.userLocation != null) {
            // Kullanıcı konumunu sakla
            _userLocationPoint = Point(
              coordinates: Position(
                state.userLocation!.longitude,
                state.userLocation!.latitude,
              ),
            );
            
            if (!_hasZoomedToLocation) {
              // İlk kez konum bulundu - GTAV gibi zoom yap
              _hasZoomedToLocation = true;
              _showLocationButton = false;
              _animatedZoomToLocation(
                state.userLocation!.latitude,
                state.userLocation!.longitude,
              );
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              MapWidget(
                key: const ValueKey('mapWidget'),
                cameraOptions: CameraOptions(
                  center: Point(
                    coordinates: Position(
                      AppConfig.defaultLongitude, // Ankara merkezi
                      AppConfig.defaultLatitude,
                    ),
                  ),
                  zoom: AppConfig.initialMapZoom, // Ankara büyük görünüm
                ),
                styleUri: MapboxStyles.STANDARD,
                onMapCreated: _onMapCreated,
                onScrollListener: _onMapScroll,
                onLongTapListener: _onMapLongPress,
              ),
              
              // Loading overlay
              if (state is MapLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              
              // Top app bar - Sadece ilk açılışta animasyonlu
              AnimatedPositioned(
                key: const ValueKey('appBar'),
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
              
              // Sağ taraf kontrolleri - Sadece ilk açılışta animasyonlu
              AnimatedPositioned(
                key: const ValueKey('rightControls'),
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
              
              // Location button - Sadece ilk açılışta animasyonlu
              if (_showLocationButton)
                AnimatedPositioned(
                  key: const ValueKey('locationButton'),
                  duration: const Duration(milliseconds: 3500),
                  curve: Curves.easeInOutCubic,
                  bottom: _minBottomSheetHeight + 12,
                  right: _showUI ? 16 : -100,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 3500),
                    opacity: _showUI ? 1.0 : 0.0,
                    child: _buildLocationButton(context, state),
                  ),
                ),
              
              // Draggable Bottom Sheet - Sadece ilk açılışta animasyonlu
              AnimatedPositioned(
                key: const ValueKey('bottomSheet'),
                duration: const Duration(milliseconds: 3500),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: _showUI ? 0 : -_minBottomSheetHeight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 3500),
                  opacity: _showUI ? 1.0 : 0.0,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightControls() {
    return Column(
      children: [
        // Zoom In
        MapControlButton(
          icon: Icons.add,
          tooltip: 'Yakınlaştır',
          onTap: () async {
            if (_mapboxMap == null) return;
            final cameraState = await _mapboxMap!.getCameraState();
            final currentZoom = cameraState.zoom;
            
            await _mapboxMap!.flyTo(
              CameraOptions(
                zoom: currentZoom + 1,
              ),
              MapAnimationOptions(duration: 300),
            );
          },
        ),
        const SizedBox(height: 8),
        
        // Zoom Out
        MapControlButton(
          icon: Icons.remove,
          tooltip: 'Uzaklaştır',
          onTap: () async {
            if (_mapboxMap == null) return;
            final cameraState = await _mapboxMap!.getCameraState();
            final currentZoom = cameraState.zoom;
            
            await _mapboxMap!.flyTo(
              CameraOptions(
                zoom: currentZoom - 1,
              ),
              MapAnimationOptions(duration: 300),
            );
          },
        ),
        const SizedBox(height: 16),
        
        // Trafik Butonu
        MapControlButton(
          icon: _showTraffic ? Icons.traffic : Icons.traffic_outlined,
          tooltip: _showTraffic ? 'Trafiği Gizle' : 'Trafiği Göster',
          onTap: () => _toggleTraffic(),
          isActive: _showTraffic,
        ),
        const SizedBox(height: 8),
        
        // Katman Seçici
        MapControlButton(
          icon: Icons.layers,
          tooltip: 'Harita Katmanı',
          onTap: () => _showLayerSelector(),
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
          setState(() {
            _currentMapStyle = layerKey;
          });
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
      case 'STANDARD':
        styleUri = MapboxStyles.STANDARD;
        break;
      case 'STANDARD_SATELLITE':
        styleUri = MapboxStyles.STANDARD_SATELLITE;
        break;
      case 'MAPBOX_STREETS':
        styleUri = MapboxStyles.MAPBOX_STREETS;
        break;
      case 'LIGHT':
        styleUri = MapboxStyles.LIGHT;
        break;
      case 'DARK':
        styleUri = MapboxStyles.DARK;
        break;
      case 'OUTDOORS':
        styleUri = MapboxStyles.OUTDOORS;
        break;
      case 'SATELLITE':
        styleUri = MapboxStyles.SATELLITE;
        break;
      case 'SATELLITE_STREETS':
        styleUri = MapboxStyles.SATELLITE_STREETS;
        break;
      default:
        styleUri = MapboxStyles.STANDARD;
    }
    
    // Stil yüklenmeye başladığında trafik durumunu kaydet
    final wasTrafficEnabled = _showTraffic;
    
    await _mapboxMap!.loadStyleURI(styleUri);
    
    // Stil yüklendikten sonra trafik durumunu geri yükle
    if (wasTrafficEnabled) {
      // Kısa bekle (stil yüklenmesi için)
      await Future.delayed(const Duration(milliseconds: 500));
      await _addTrafficLayers();
    }
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
          setState(() {
            _showLocationButton = false;
          });
          
          final bloc = context.read<MapBloc>();
          bloc.add(const MapUserLocationRequested());
          
          // Konuma git - HIZLI, animasyonsuz
          await Future.delayed(const Duration(milliseconds: 100));
          if (_userLocationPoint != null) {
            await _moveToLocationFast(
              _userLocationPoint!.coordinates.lat.toDouble(),
              _userLocationPoint!.coordinates.lng.toDouble(),
            );
          }
        },
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Türkiye için harita optimizasyonları
    
    // 1. Zoom limitleri ve coğrafi sınırlar - Türkiye için optimize
    await mapboxMap.setBounds(
      CameraBoundsOptions(
        bounds: CoordinateBounds(
          southwest: Point(
            coordinates: Position(
              AppConfig.turkeyMinLng,
              AppConfig.turkeyMinLat,
            ),
          ),
          northeast: Point(
            coordinates: Position(
              AppConfig.turkeyMaxLng,
              AppConfig.turkeyMaxLat,
            ),
          ),
          infiniteBounds: false, // Türkiye sınırlarıyla kısıtla
        ),
        minZoom: AppConfig.minZoom,
        maxZoom: AppConfig.maxZoom,
      ),
    );
    
    // 2. Scale bar (zoom göstergesi) gizle
    await mapboxMap.scaleBar.updateSettings(
      ScaleBarSettings(enabled: false),
    );
    
    // Pusula ayarları - aşağıya al ve tıklanabilir yap
    await mapboxMap.compass.updateSettings(
      CompassSettings(
        enabled: true,
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: 120.0, // Daha aşağıya aldık
        marginRight: 16.0,
        clickable: true, // Tıklanabilir, tıklanınca harita kuzeye döner
      ),
    );
  }

  // Trafik katmanlarını ekle (yardımcı metod)
  Future<void> _addTrafficLayers() async {
    if (_mapboxMap == null) return;
    
    try {
      // 1. Traffic source ekle
      await _mapboxMap!.style.addSource(
        VectorSource(
          id: 'mapbox-traffic-source',
          url: 'mapbox://mapbox.mapbox-traffic-v1',
        ),
      );
      
      // 2. Sarı trafik (moderate - orta yoğunluk)
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'traffic-moderate',
          sourceId: 'mapbox-traffic-source',
          sourceLayer: 'traffic',
          filter: ['==', ['get', 'congestion'], 'moderate'],
          lineWidth: 2.5,
          lineColor: 0xFFFFEB3B, // Sarı
        ),
      );
      
      // 3. Turuncu trafik (heavy - yüksek yoğunluk)
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'traffic-heavy',
          sourceId: 'mapbox-traffic-source',
          sourceLayer: 'traffic',
          filter: ['==', ['get', 'congestion'], 'heavy'],
          lineWidth: 2.5,
          lineColor: 0xFFFF9800, // Turuncu
        ),
      );
      
      // 4. Kırmızı trafik (severe - çok yüksek yoğunluk)
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'traffic-severe',
          sourceId: 'mapbox-traffic-source',
          sourceLayer: 'traffic',
          filter: ['==', ['get', 'congestion'], 'severe'],
          lineWidth: 2.5,
          lineColor: 0xFFF44336, // Kırmızı
        ),
      );
      
      debugPrint('✅ Trafik katmanları eklendi');
    } catch (e) {
      debugPrint('❌ Trafik katmanı ekleme hatası: $e');
      rethrow;
    }
  }

  // Trafik katmanlarını kaldır (yardımcı metod)
  Future<void> _removeTrafficLayers() async {
    if (_mapboxMap == null) return;
    
    try {
      await _mapboxMap!.style.removeStyleLayer('traffic-moderate');
      await _mapboxMap!.style.removeStyleLayer('traffic-heavy');
      await _mapboxMap!.style.removeStyleLayer('traffic-severe');
      await _mapboxMap!.style.removeStyleSource('mapbox-traffic-source');
      
      // Haritayı yenile (render güncelle)
      await _mapboxMap!.triggerRepaint();
      
      debugPrint('✅ Trafik katmanları kaldırıldı');
    } catch (e) {
      debugPrint('Layer silme hatası (normal olabilir): $e');
    }
  }

  // Trafik katmanını aç/kapa
  Future<void> _toggleTraffic() async {
    if (_mapboxMap == null) return;
    
    setState(() {
      _showTraffic = !_showTraffic;
    });

    try {
      if (_showTraffic) {
        await _addTrafficLayers();
        
        if (mounted) {
          CustomNotification.showSuccess(
            context,
            message: '🚦 Sarı: Orta | Turuncu: Yoğun | Kırmızı: Çok Yoğun',
          );
        }
      } else {
        await _removeTrafficLayers();
      }
    } catch (e) {
      debugPrint('❌ Trafik toggle hatası: $e');
      
      // Hata varsa state'i geri al
      setState(() {
        _showTraffic = !_showTraffic;
      });
      
      if (mounted) {
        CustomNotification.showError(
          context,
          message: 'Trafik bilgisi yüklenemedi: $e',
        );
      }
    }
  }

  // ==================== ROTA FONKSİYONLARI ====================
  
  /// Rota hesapla ve haritada göster
  Future<void> _calculateRoute(double destLat, double destLng) async {
    if (_mapboxMap == null || _userLocationPoint == null) {
      CustomNotification.showError(
        context,
        message: 'Konumunuz alınamadı',
      );
      return;
    }
    
    try {
      // Loading göster
      CustomNotification.showInfo(
        context,
        message: '🔍 Rota hesaplanıyor...',
        duration: const Duration(seconds: 2),
      );
      
      // Rota hesapla
      final response = await _directionsService.getRoute(
        startLat: _userLocationPoint!.coordinates.lat.toDouble(),
        startLng: _userLocationPoint!.coordinates.lng.toDouble(),
        endLat: destLat,
        endLng: destLng,
        profile: 'driving-traffic', // Trafik dahil sürüş
      );
      
      if (response == null || response.routes.isEmpty) {
        if (mounted) {
          CustomNotification.showError(
            context,
            message: 'Rota bulunamadı',
          );
        }
        return;
      }
      
      // En iyi rotayı al
      final route = response.routes.first;
      
      setState(() {
        _currentRoute = route;
        _routeDestination = Point(coordinates: Position(destLng, destLat));
        _isRouteActive = true;
      });
      
      // Haritada göster
      await _drawRoute(route);
      
      // Başarı mesajı
      if (mounted) {
        CustomNotification.showSuccess(
          context,
          message: '✅ ${route.distanceText} • ${route.durationText}',
        );
      }
      
      // Rotaya zoom yap
      await _zoomToRoute(route);
      
    } catch (e) {
      debugPrint('❌ Rota hesaplama hatası: $e');
      if (mounted) {
        CustomNotification.showError(
          context,
          message: 'Rota hesaplanamadı: $e',
        );
      }
    }
  }
  
  /// Rotayı haritada çiz
  Future<void> _drawRoute(directions.Route route) async {
    if (_mapboxMap == null) return;
    
    try {
      // Önce eski rotayı temizle
      await _clearRoute();
      
      // GeoJSON oluştur
      final coordinates = route.geometry.map((coord) {
        return [coord[0], coord[1]]; // [lng, lat]
      }).toList();
      
      final geoJson = {
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': coordinates,
        },
      };
      
      // Rota source ekle
      await _mapboxMap!.style.addSource(
        GeoJsonSource(
          id: 'route-source',
          data: json.encode(geoJson),
        ),
      );
      
      // Rota çizgisi (altında gölge gibi)
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'route-line-shadow',
          sourceId: 'route-source',
          lineWidth: 8.0,
          lineColor: 0x80000000, // Yarı saydam siyah
          lineBlur: 4.0,
        ),
      );
      
      // Ana rota çizgisi
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'route-line',
          sourceId: 'route-source',
          lineWidth: 6.0,
          lineColor: 0xFF2196F3, // Mavi
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      
      // Hedef marker ekle
      if (_routeDestination != null) {
        await _mapboxMap!.annotations.createPointAnnotationManager().then((manager) async {
          await manager.create(
            PointAnnotationOptions(
              geometry: _routeDestination!,
              iconImage: 'marker', // Varsayılan marker
              iconSize: 1.5,
            ),
          );
        });
      }
      
      debugPrint('✅ Rota çizildi');
    } catch (e) {
      debugPrint('❌ Rota çizme hatası: $e');
      rethrow;
    }
  }
  
  /// Rotayı temizle
  Future<void> _clearRoute() async {
    if (_mapboxMap == null) return;
    
    try {
      // Layer'ları sil
      await _mapboxMap!.style.removeStyleLayer('route-line');
      await _mapboxMap!.style.removeStyleLayer('route-line-shadow');
      await _mapboxMap!.style.removeStyleSource('route-source');
      
      setState(() {
        _currentRoute = null;
        _routeDestination = null;
        _isRouteActive = false;
      });
      
      debugPrint('✅ Rota temizlendi');
    } catch (e) {
      debugPrint('Rota temizleme hatası (normal olabilir): $e');
    }
  }
  
  /// Rotaya zoom yap
  Future<void> _zoomToRoute(directions.Route route) async {
    if (_mapboxMap == null || route.geometry.isEmpty) return;
    
    try {
      // Rota sınırlarını hesapla
      double minLat = route.geometry.first[1];
      double maxLat = route.geometry.first[1];
      double minLng = route.geometry.first[0];
      double maxLng = route.geometry.first[0];
      
      for (final coord in route.geometry) {
        final lng = coord[0];
        final lat = coord[1];
        
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
      
      // Padding ekle
      final padding = 0.01; // ~1km
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;
      
      // Merkez hesapla
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Zoom seviyesi hesapla (basit yaklaşım)
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      
      double zoom = 14.0;
      if (maxDiff > 0.5) {
        zoom = 10.0;
      } else if (maxDiff > 0.2) {
        zoom = 11.0;
      } else if (maxDiff > 0.1) {
        zoom = 12.0;
      } else if (maxDiff > 0.05) {
        zoom = 13.0;
      }
      
      // Animasyonlu zoom
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: zoom,
        ),
        MapAnimationOptions(duration: 1500),
      );
    } catch (e) {
      debugPrint('❌ Rota zoom hatası: $e');
    }
  }

  // GTAV gibi smooth zoom animasyonu - uzaktan yakına
  Future<void> _animatedZoomToLocation(double lat, double lng) async {
    if (_mapboxMap == null) return;

    // Önce biraz bekle - haritanın yüklenmesini izle
    await Future.delayed(const Duration(milliseconds: 800));

    // UI elementlerini göstermeye başla (zoom ile birlikte)
    if (mounted) {
      setState(() {
        _showUI = true;
      });
    }

    // 3.5 saniye içinde smooth zoom - UI animasyonları da aynı sürede
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 3500), // UI animasyonları ile senkronize
    );
  }

  // Hızlı konum değişimi (location button için) - ANİMASYONSUZ
  Future<void> _moveToLocationFast(double lat, double lng) async {
    if (_mapboxMap == null) return;

    // Çok hızlı geçiş (500ms) - UI animasyonu YOK
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 500), // Çok hızlı
    );
  }

  Widget _buildBottomSheet(BuildContext context, MapState state) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // setState yerine direkt güncelleme - daha hızlı
        final delta = -details.delta.dy;
        final dragRange = _maxBottomSheetHeight - _minBottomSheetHeight;
        
        // Position güncelle (0.0 - 1.0 arası)
        _bottomSheetPosition += delta / dragRange;
        _bottomSheetPosition = _bottomSheetPosition.clamp(0.0, 1.0);
        
        // Her frame'de rebuild - çok daha smooth
        setState(() {});
      },
      onVerticalDragEnd: (details) {
        // Hıza göre snap yap
        final velocity = details.velocity.pixelsPerSecond.dy;
        
        if (velocity.abs() > 500) {
          // Hızlı sürükleme - yönüne göre aç/kapa
          if (velocity < 0) {
            _openBottomSheet();
          } else {
            _closeBottomSheet();
          }
        } else {
          // Yavaş sürükleme - pozisyona göre snap
          if (_bottomSheetPosition > 0.5) {
            _openBottomSheet();
          } else {
            _closeBottomSheet();
          }
        }
      },
      child: Container(
        // AnimatedContainer yerine Container - daha hızlı yanıt
        height: _minBottomSheetHeight + 
                (_maxBottomSheetHeight - _minBottomSheetHeight) * _bottomSheetPosition,
        decoration: BoxDecoration(
          color: AppDesign.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDesign.panelRadius),
            topRight: Radius.circular(AppDesign.panelRadius),
          ),
          boxShadow: AppDesign.panelShadow,
        ),
        child: Column(
          children: [
            // Handle (tutamak)
            const PanelHandle(),
            
            // İçerik
            Expanded(
              child: _buildBottomSheetContent(),
            ),
          ],
        ),
      ),
    );
  }

  void _openBottomSheet() {
    // Animasyonlu açılma
    _bottomSheetController.forward().then((_) {
      setState(() {
        _bottomSheetPosition = 1.0;
      });
    });
    
    // Hızlı animasyon
    const duration = Duration(milliseconds: 200);
    final startPosition = _bottomSheetPosition;
    final startTime = DateTime.now();
    
    void animate() {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      
      setState(() {
        _bottomSheetPosition = startPosition + (1.0 - startPosition) * progress;
      });
      
      if (progress < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), animate);
      }
    }
    
    animate();
  }

  void _closeBottomSheet() {
    // Animasyonlu kapanma
    _bottomSheetController.reverse().then((_) {
      setState(() {
        _bottomSheetPosition = 0.0;
      });
    });
    
    // Hızlı animasyon
    const duration = Duration(milliseconds: 200);
    final startPosition = _bottomSheetPosition;
    final startTime = DateTime.now();
    
    void animate() {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final progress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      
      setState(() {
        _bottomSheetPosition = startPosition * (1.0 - progress);
      });
      
      if (progress < 1.0) {
        Future.delayed(const Duration(milliseconds: 16), animate);
      }
    }
    
    animate();
  }

  Widget _buildBottomSheetContent() {
    // İçeriklerin her zaman güvenli bölgede kalması için padding
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final contentBottomPadding = _contentSafeZone - systemBottomPadding;
    
    // Panel açıksa kaydırılabilir, kapalıysa kaydırmayı engelle
    final isExpanded = _bottomSheetPosition > 0.3; // %30'dan fazla açıksa expanded sayılır
    
    return SingleChildScrollView(
      physics: isExpanded 
          ? const AlwaysScrollableScrollPhysics() // Açıkken kaydırılabilir
          : const NeverScrollableScrollPhysics(), // Kapalıyken kaydırma yok
      padding: EdgeInsets.only(
        left: AppDesign.panelPadding,
        right: AppDesign.panelPadding,
        top: 12,
        bottom: contentBottomPadding > 0 ? contentBottomPadding : 20, // Minimum 20px
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rota bilgisi (aktif rota varsa göster)
          if (_isRouteActive && _currentRoute != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppDesign.primaryColor,
                    AppDesign.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Rota Bilgisi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await _clearRoute();
                          if (mounted) {
                            CustomNotification.showInfo(
                              context,
                              message: 'Rota temizlendi',
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesafe',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentRoute!.distanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Süre',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentRoute!.durationText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Arama çubuğu ve profil avatarı - Modern Tasarım
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppDesign.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Arama çubuğu
                  Expanded(
                    child: SearchBarWidget(
                      hintText: 'Konum girin',
                      onTap: () {
                        // Arama ekranına git (ileride implement edilecek)
                        debugPrint('Arama çubuğuna tıklandı');
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Profil avatarı
                  UserAvatar(
                    initials: _getInitials(_currentUser?.displayName ?? 'U'),
                    onTap: () => _openProfilePanel(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Panel açıldığında gösterilecek içerikler - akıllı animasyon
          _buildSmartAnimatedContent(
            // Bu içeriğin sığması için gereken minimum panel yüksekliği
            requiredHeight: 200.0, // Başlık + 3 item için yaklaşık yükseklik
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Text(
                  'Son Aramalar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Placeholder içerik
                _buildPlaceholderItem(Icons.location_on, 'Bartın Üniversitesi'),
                const SizedBox(height: 8),
                _buildPlaceholderItem(Icons.location_on, 'Bartın Merkez'),
                const SizedBox(height: 8),
                _buildPlaceholderItem(Icons.location_on, 'Amasra Kalesi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Akıllı animasyonlu içerik - İçeriğin kendi yüksekliğine göre görünür
  Widget _buildSmartAnimatedContent({
    required double requiredHeight,
    required Widget child,
  }) {
    // Şu anki panel yüksekliği
    final currentHeight = _minBottomSheetHeight + 
        (_maxBottomSheetHeight - _minBottomSheetHeight) * _bottomSheetPosition;
    
    // Progress: Panel minimum yükseklikten requiredHeight kadar açıldığında 1.0 olur
    final progress = ((currentHeight - _minBottomSheetHeight) / requiredHeight).clamp(0.0, 1.0);
    
    return AnimatedOpacity(
      opacity: progress,
      duration: AppDesign.fastAnimation,
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: 0.92 + (progress * 0.08), // 0.92'den 1.0'a kadar büyür
        duration: AppDesign.fastAnimation,
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: Offset(0, 0.15 * (1 - progress)), // Aşağıdan yukarı kayar
          duration: AppDesign.fastAnimation,
          curve: Curves.easeOut,
          child: progress > 0.05 ? child : const SizedBox.shrink(), // %5'ten az ise gizle
        ),
      ),
    );
  }

  // İsimden baş harfleri al
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildPlaceholderItem(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppDesign.overlayColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppDesign.dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppDesign.iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppDesign.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppDesign.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

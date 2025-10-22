import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/services/directions_service.dart' as directions;
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/animated_notification.dart';

// ignore_for_file: use_build_context_synchronously

/// Arama ve rota planlama ekranı - Tek ekranda her şey
class SearchAndRouteScreen extends StatefulWidget {
  final Position? userLocation; // Kullanıcının mevcut konumu
  
  const SearchAndRouteScreen({
    super.key,
    this.userLocation,
  });

  @override
  State<SearchAndRouteScreen> createState() => _SearchAndRouteScreenState();
}

class _SearchAndRouteScreenState extends State<SearchAndRouteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GeocodingService _geocodingService = GeocodingService();
  final SearchHistoryService _historyService = SearchHistoryService();
  final directions.DirectionsService _directionsService = directions.DirectionsService();
  late final AnalyticsService _analyticsService;
  
  List<GeocodingResult> _searchResults = [];
  List<GeocodingResult> _searchHistory = [];
  List<SavedRoute> _savedRoutes = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounce;
  
  GeocodingResult? _startLocation; // Başlangıç (varsayılan: GPS)
  GeocodingResult? _destination; // Hedef
  bool _showStartPanel = false; // Başlangıç değiştirme paneli
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadHistory();
    _loadSavedRoutes();
    _initializeStartLocation();
  }

  Future<void> _initializeServices() async {
    // AnalyticsService'i initialize et
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;
    _analyticsService = AnalyticsService(firestore, prefs);
    await _analyticsService.initialize();
  }

  Future<void> _initializeStartLocation() async {
    // Widget'tan gelen konumu kullan veya yeni GPS konumu al
    if (widget.userLocation != null) {
      setState(() {
        _startLocation = GeocodingResult(
          id: 'current_location',
          placeName: 'Mevcut Konum',
          address: 'GPS konumunuz',
          latitude: widget.userLocation!.latitude,
          longitude: widget.userLocation!.longitude,
          placeType: 'current',
        );
      });
    } else {
      // GPS konumunu al
      try {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _startLocation = GeocodingResult(
              id: 'current_location',
              placeName: 'Mevcut Konum',
              address: 'GPS konumunuz',
              latitude: position.latitude,
              longitude: position.longitude,
              placeType: 'current',
            );
          });
        }
      } catch (e) {
        debugPrint('GPS konumu alınamadı: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _historyService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await _historyService.getSavedRoutes();
    if (mounted) {
      setState(() {
        _savedRoutes = routes;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }
    
    // 500ms debounce
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await _geocodingService.search(
        query: query,
        proximityLat: widget.userLocation?.latitude,
        proximityLng: widget.userLocation?.longitude,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectDestination(GeocodingResult location) async {
    // Geçmişe ekle
    await _historyService.addToHistory(location);
    
    setState(() {
      _destination = location;
    });
    
    // Rotayı hesapla
    if (_startLocation != null) {
      _calculateRoute();
    }
  }

  Future<void> _calculateRoute() async {
    if (_startLocation == null || _destination == null) return;
    
    try {
      final routes = await _directionsService.getMultipleRoutes(
        startLat: _startLocation!.latitude,
        startLng: _startLocation!.longitude,
        endLat: _destination!.latitude,
        endLng: _destination!.longitude,
      );
      
      if (routes.isEmpty) {
        if (mounted) {
          AnimatedNotification.showError(context, message: 'Rota bulunamadı');
        }
        return;
      }
      
      // Analytics: Rota arama olayını logla
      await _analyticsService.logRouteSearch(
        destination: _destination!.placeName,
      );
      
      // Ana harita ekranına rotalarla dön
      if (mounted) {
        Navigator.pop(context, {
          'routes': routes,
          'origin': _startLocation,
          'destination': _destination,
        });
      }
    } catch (e) {
      if (mounted) {
        AnimatedNotification.showError(context, message: 'Rota hesaplanamadı: $e');
      }
    }
  }

  Future<void> _showSaveLocationDialog() async {
    // Kaydedilen lokasyon ekleme dialogu (basit)
    // İleride implement edilecek
    AnimatedNotification.showInfo(context, message: 'Yakında eklenecek');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rota Planla',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Geçmişi temizle butonu (geliştirme için)
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () async {
              await _historyService.clearHistory();
              await _historyService.clearSavedRoutes();
              _loadHistory();
              _loadSavedRoutes();
              if (mounted) {
                AnimatedNotification.showInfo(context, message: 'Geçmiş temizlendi');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Başlangıç/Hedef paneli
          _buildLocationPanel(),
          
          const Divider(height: 1),
          
          // Arama sonuçları veya default içerik
          Expanded(
            child: _showResults ? _buildSearchResults() : _buildDefaultContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Başlangıç
          GestureDetector(
            onTap: () {
              setState(() {
                _showStartPanel = !_showStartPanel;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.circle, color: Colors.blue, size: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _startLocation?.placeName ?? 'Başlangıç seç',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _showStartPanel ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          
          // Başlangıç değiştirme paneli
          if (_showStartPanel)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 24),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Başlangıç konumu ara',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  // Başlangıç için arama
                  _onSearchChanged(value);
                },
              ),
            ),
          
          const SizedBox(height: 12),
          
          Container(
            height: 30,
            width: 2,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.only(left: 5),
          ),
          
          const SizedBox(height: 12),
          
          // Hedef (Ana arama)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nereye gitmek istiyorsunuz?',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade600),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _showResults = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Sonuç bulunamadı',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_on, color: Colors.grey),
          title: Text(result.shortTitle),
          subtitle: Text(result.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            if (_showStartPanel) {
              // Başlangıç seçimi
              setState(() {
                _startLocation = result;
                _showStartPanel = false;
              });
            } else {
              // Hedef seçimi
              _selectDestination(result);
            }
          },
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kaydedilenler
          if (_savedRoutes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kaydedilenler',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppDesign.primaryColor),
                    onPressed: _showSaveLocationDialog,
                  ),
                ],
              ),
            ),
            ..._savedRoutes.take(5).map((route) {
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(route.shortName),
                subtitle: Text(route.destination.shortTitle, maxLines: 1),
                onTap: () => _selectDestination(route.destination),
              );
            }),
            const Divider(height: 1),
          ],
          
          // Son Aramalar
          if (_searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Son Aramalar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ..._searchHistory.take(10).map((location) {
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(location.shortTitle),
                subtitle: Text(location.fullAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _selectDestination(location),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  onPressed: () async {
                    await _historyService.removeFromHistory(location.id);
                    _loadHistory();
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

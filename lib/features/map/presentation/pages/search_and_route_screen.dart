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
  final TextEditingController _startSearchController = TextEditingController();
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
  bool _isCalculating = false; // Rota hesaplama durumu
  
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
    _startSearchController.dispose();
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

  Future<void> _selectLocation(GeocodingResult location, {required bool isForStart}) async {
    if (isForStart) {
      // Başlangıç konumu seç
      setState(() {
        _startLocation = location;
        _showStartPanel = false;
        _startSearchController.clear();
        _showResults = false;
      });
    } else {
      // Hedef konum seç - sadece yerleştir, hesaplama yok
      await _historyService.addToHistory(location);
      setState(() {
        _destination = location;
        _searchController.clear();
        _showResults = false;
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_startLocation == null || _destination == null) return;
    
    setState(() {
      _isCalculating = true;
    });
    
    try {
      final routes = await _directionsService.getMultipleRoutes(
        startLat: _startLocation!.latitude,
        startLng: _startLocation!.longitude,
        endLat: _destination!.latitude,
        endLng: _destination!.longitude,
      );
      
      if (routes.isEmpty) {
        if (mounted) {
          setState(() {
            _isCalculating = false;
          });
          NotificationHelper.show(context, 'Rota bulunamadı', isError: true);
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
        setState(() {
          _isCalculating = false;
        });
        NotificationHelper.show(context, 'Rota hesaplanamadı: $e', isError: true);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCalculating,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Modern Header
                  _buildModernHeader(),
                  
                  // Arama sonuçları veya default içerik
                  Expanded(
                    child: _showResults ? _buildSearchResults() : _buildDefaultContent(),
                  ),
                  
                  // Rota Hesapla Butonu
                  if (_startLocation != null && _destination != null && !_isCalculating)
                    _buildCalculateButton(),
                ],
              ),
              
              // Yükleme animasyonu overlay
              if (_isCalculating)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Rota hesaplanıyor...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tüm metrikler hesaplanıyor',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Material(
          color: AppDesign.primaryColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _calculateRoute,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rota Hesapla',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close button ve title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Rota Planla',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // Lokasyon kartları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Başlangıç kartı
                _buildLocationCard(
                  icon: Icons.my_location_rounded,
                  iconColor: AppDesign.primaryColor,
                  title: _startLocation?.placeName ?? 'Mevcut Konum',
                  subtitle: _startLocation?.address ?? 'GPS konumunuz',
                  onTap: () {
                    setState(() => _showStartPanel = !_showStartPanel);
                  },
                  trailing: Icon(
                    _showStartPanel ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                // Başlangıç değiştirme paneli
                if (_showStartPanel) ...[
                  const SizedBox(height: 8),
                  _buildSearchField(
                    controller: _startSearchController,
                    hintText: 'Başlangıç konumu ara...',
                    isForStart: true,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Hedef kartı (Ana arama)
                _buildLocationCard(
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.red,
                  title: _destination?.placeName ?? 'Nereye gitmek istiyorsunuz?',
                  subtitle: _destination?.address,
                  isClickable: false,
                  child: _buildSearchField(
                    controller: _searchController,
                    hintText: 'Hedef ara...',
                    isForStart: false,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Widget? child,
    bool isClickable = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child ?? Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isClickable ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    TextEditingController? controller,
    required String hintText,
    required bool isForStart,
  }) {
    final ctrl = controller ?? TextEditingController();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: TextField(
        controller: ctrl,
        autofocus: !isForStart,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                  onPressed: () {
                    ctrl.clear();
                    setState(() {
                      _showResults = false;
                      _searchResults = [];
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) {
          if (isForStart) {
            // Başlangıç için arama
            _onSearchChanged(value);
          } else {
            // Hedef için arama
            _onSearchChanged(value);
          }
        },
      ),
    );
  }



  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppDesign.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Aranıyor...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Sonuç bulunamadı',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı anahtar kelimeler deneyin',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildResultCard(result, isForStart: _showStartPanel);
      },
    );
  }

  Widget _buildResultCard(GeocodingResult result, {required bool isForStart}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectLocation(result, isForStart: isForStart),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.shortTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.fullAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kaydedilenler
          if (_savedRoutes.isNotEmpty) ...[
            _buildSectionHeader('Kaydedilenler', Icons.star_rounded),
            const SizedBox(height: 12),
            ..._savedRoutes.take(5).map((route) {
              return _buildHistoryCard(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                title: route.shortName,
                subtitle: route.destination.shortTitle,
                onTap: () => _selectLocation(route.destination, isForStart: false),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          // Son Aramalar
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionHeader('Son Aramalar', Icons.history_rounded),
            const SizedBox(height: 12),
            ..._searchHistory.take(10).map((location) {
              return _buildHistoryCard(
                icon: Icons.access_time_rounded,
                iconColor: Colors.grey.shade600,
                title: location.shortTitle,
                subtitle: location.fullAddress,
                onTap: () => _selectLocation(location, isForStart: false),
                onDelete: () async {
                  await _historyService.removeFromHistory(location.id);
                  _loadHistory();
                },
              );
            }),
          ],
          
          // Boş durum
          if (_searchHistory.isEmpty && _savedRoutes.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppDesign.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: 48,
                      color: AppDesign.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nereye gitmek istiyorsunuz?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Arama yaparak rotanızı planlayın',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppDesign.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey.shade400),
                    onPressed: onDelete,
                  )
                else
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

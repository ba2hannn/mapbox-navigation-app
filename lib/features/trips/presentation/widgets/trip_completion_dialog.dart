import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../trips/data/services/trip_service.dart';
import '../../../../core/services/saved_places_service.dart';

class TripCompletionDialog extends StatefulWidget {
  final SavedPlace destination;
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;

  const TripCompletionDialog({
    super.key,
    required this.destination,
    required this.firestore,
    required this.prefs,
  });

  @override
  State<TripCompletionDialog> createState() => _TripCompletionDialogState();
}

class _TripCompletionDialogState extends State<TripCompletionDialog> {
  final TripService _tripService = TripService();
  late final AnalyticsService _analyticsService;
  final TextEditingController _fuelUsedController = TextEditingController();
  final TextEditingController _fuelCostController = TextEditingController();
  final TextEditingController _tollCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _trafficLevel = 5.0; // 0-10 arası
  int _rating = 3; // 1-5 arası
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _analyticsService = AnalyticsService(widget.firestore, widget.prefs);
    _analyticsService.initialize();
  }

  @override
  void dispose() {
    _fuelUsedController.dispose();
    _fuelCostController.dispose();
    _tollCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTripCompletion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Yeni bir trip oluştur (gerçek navigasyon olmadan)
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      // Varsayılan araç bilgilerini al
      final vehicleInfo = await _getDefaultVehicleInfo(userId);

      // Yaklaşık mesafe hesapla (şimdilik sabit, gerçek konumdan hesaplanabilir)
      final estimatedDistance = 10.0; // km, gerçek hesaplamayla değiştirilebilir

      final tripId = await _tripService.startTrip(
        userId: userId,
        vehicleId: vehicleInfo['id'] ?? 'default',
        startLat: 0.0, // Gerçek konumdan al
        startLng: 0.0,
        endLat: widget.destination.location.latitude,
        endLng: widget.destination.location.longitude,
        estimatedDistanceKm: estimatedDistance,
      );

      // Trip'i tamamla
      final fuelUsed = _fuelUsedController.text.isNotEmpty
          ? double.tryParse(_fuelUsedController.text.replaceAll(',', '.'))
          : null;
      final fuelCost = _fuelCostController.text.isNotEmpty
          ? double.tryParse(_fuelCostController.text.replaceAll(',', '.'))
          : null;
      final tollCost = _tollCostController.text.isNotEmpty
          ? double.tryParse(_tollCostController.text.replaceAll(',', '.'))
          : null;

      await _tripService.completeTrip(
        tripId: tripId,
        fuelUsed: fuelUsed,
        fuelCost: fuelCost,
        tollCost: tollCost,
        trafficLevel: _trafficLevel.round(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Analytics'e kaydet
      await _analyticsService.logRouteCompleted(estimatedDistance);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yolculuk kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    // Firebase Auth'tan user id al
    // Bu kısım uygulamanızın auth yapısına göre değişebilir
    return 'current_user_id'; // Gerçek implementasyon gerekli
  }

  Future<Map<String, String>> _getDefaultVehicleInfo(String userId) async {
    // Varsayılan araç bilgilerini al
    // Bu kısım uygulamanızın araç yönetim yapısına göre değişebilir
    return {'id': 'default_vehicle', 'name': 'Varsayılan Araç'};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppDesign.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppDesign.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yolculuğunuz Nasıl Geçti?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.textPrimary,
                        ),
                      ),
                      Text(
                        widget.destination.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppDesign.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Yıldız değerlendirmesi
            const Text(
              'Genel Değerlendirme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppDesign.primaryColor,
                    size: 32,
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Opsiyonel alanlar
            const Text(
              'Detaylar (İsteğe Bağlı)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Yakıt miktarı
            TextField(
              controller: _fuelUsedController,
              decoration: InputDecoration(
                labelText: 'Kullanılan Yakıt (Litre)',
                hintText: 'Örn: 25.5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.local_gas_station),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Yakıt maliyeti
            TextField(
              controller: _fuelCostController,
              decoration: InputDecoration(
                labelText: 'Yakıt Maliyeti (TL)',
                hintText: 'Örn: 1020',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.payments),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Gişe ücreti
            TextField(
              controller: _tollCostController,
              decoration: InputDecoration(
                labelText: 'Gişe Ücreti (TL)',
                hintText: 'Örn: 150',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.toll),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Trafik seviyesi
            const Text(
              'Trafik Yoğunluğu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppDesign.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Az', style: TextStyle(color: AppDesign.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _trafficLevel,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _trafficLevel.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _trafficLevel = value;
                      });
                    },
                  ),
                ),
                const Text('Çok', style: TextStyle(color: AppDesign.textSecondary)),
              ],
            ),

            const SizedBox(height: 20),

            // Notlar
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notlar',
                hintText: 'Yolculuk hakkında notlar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 32),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Atla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTripCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
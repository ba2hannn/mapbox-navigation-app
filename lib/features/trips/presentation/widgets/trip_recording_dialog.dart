import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../trips/data/services/trip_service.dart';

class TripRecordingDialog extends StatefulWidget {
  final String tripId;
  final double estimatedDistance;
  final String vehicleName;
  final FirebaseFirestore firestore;
  final SharedPreferences prefs;

  const TripRecordingDialog({
    super.key,
    required this.tripId,
    required this.estimatedDistance,
    required this.vehicleName,
    required this.firestore,
    required this.prefs,
  });

  @override
  State<TripRecordingDialog> createState() => _TripRecordingDialogState();
}

class _TripRecordingDialogState extends State<TripRecordingDialog> {
  final TripService _tripService = TripService();
  late final AnalyticsService _analyticsService;
  final TextEditingController _fuelUsedController = TextEditingController();
  final TextEditingController _fuelCostController = TextEditingController();
  final TextEditingController _tollCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _trafficLevel = 5.0; // 0-10 arası
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
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTrip() async {
    if (_fuelUsedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen kullanılan yakıt miktarını girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fuelUsed = double.tryParse(_fuelUsedController.text.replaceAll(',', '.'));
      final fuelCost = _fuelCostController.text.isNotEmpty
          ? double.tryParse(_fuelCostController.text.replaceAll(',', '.'))
          : null;
      final tollCost = _tollCostController.text.isNotEmpty
          ? double.tryParse(_tollCostController.text.replaceAll(',', '.'))
          : null;

      if (fuelUsed == null || fuelUsed <= 0) {
        throw Exception('Geçersiz yakıt miktarı');
      }

      await _tripService.completeTrip(
        tripId: widget.tripId,
        fuelUsed: fuelUsed,
        fuelCost: fuelCost,
        tollCost: tollCost,
        trafficLevel: _trafficLevel.round(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Analytics'e rota tamamlandığını logla
      await _analyticsService.logRouteCompleted(widget.estimatedDistance);

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
                    Icons.directions_car,
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
                        'Yolculuğu Kaydet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppDesign.textPrimary,
                        ),
                      ),
                      Text(
                        widget.vehicleName,
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

            // Mesafe bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Tahmini Mesafe: ${widget.estimatedDistance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppDesign.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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

            // Yakıt maliyeti (opsiyonel)
            TextField(
              controller: _fuelCostController,
              decoration: InputDecoration(
                labelText: 'Yakıt Maliyeti (TL) - Opsiyonel',
                hintText: 'Örn: 1020',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.payments),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Gişe ücreti (opsiyonel)
            TextField(
              controller: _tollCostController,
              decoration: InputDecoration(
                labelText: 'Gişe Ücreti (TL) - Opsiyonel',
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
                labelText: 'Notlar - Opsiyonel',
                hintText: 'Yolculuk hakkında notlar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
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
                      'Vazgeç',
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
                    onPressed: _isLoading ? null : _saveTrip,
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
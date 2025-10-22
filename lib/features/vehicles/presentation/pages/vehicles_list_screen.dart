import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/vehicle_model.dart';
import 'add_vehicle_screen.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  final _firebaseService = FirebaseService();
  List<VehicleModel> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _firebaseService.currentUserId;
      
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final snapshot = await _firebaseService
          .userVehicles(userId)
          .get();

      final vehicles = snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();

      // Alfabetik sıralama (marka + model)
      vehicles.sort((a, b) {
        final aName = '${a.brand} ${a.model}'.toLowerCase();
        final bName = '${b.brand} ${b.model}'.toLowerCase();
        return aName.compareTo(bName);
      });

      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Araçlar yüklenemedi: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimary, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        title: const Text(
          'Araçlarım',
          style: TextStyle(
            color: AppDesign.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppDesign.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddVehicleScreen(),
                  ),
                );
                
                if (result == true) {
                  _loadVehicles();
                }
              },
              icon: const Icon(Icons.add, color: AppDesign.primaryColor, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
      floatingActionButton: !_isLoading && _vehicles.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppDesign.primaryColor.withAlpha(30),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVehicleScreen(),
                    ),
                  );
                  
                  if (result == true) {
                    _loadVehicles();
                  }
                },
                backgroundColor: AppDesign.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Yeni Araç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppDesign.primaryColor.withAlpha(8),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppDesign.primaryColor.withAlpha(20),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 70,
              color: AppDesign.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Henüz araç eklemediniz',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppDesign.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Araç ekleyerek rota hesaplamalarınızı\ndaha hassas yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppDesign.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddVehicleScreen(),
                ),
              );
              
              if (result == true) {
                _loadVehicles();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 36,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              shadowColor: AppDesign.primaryColor.withAlpha(30),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'İlk Aracınızı Ekleyin',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    final vehicleClassData = {
      '1': {'emoji': '🚗', 'name': 'Sınıf 1'},
      '2': {'emoji': '🚐', 'name': 'Sınıf 2'},
      '3': {'emoji': '🚌', 'name': 'Sınıf 3'},
      '4': {'emoji': '🚚', 'name': 'Sınıf 4'},
      '5': {'emoji': '🚛', 'name': 'Sınıf 5'},
    };

    final classInfo = vehicleClassData[vehicle.vehicleClass] ?? 
                      {'emoji': '🚗', 'name': 'Sınıf 1'};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${vehicle.brand} ${vehicle.model} detay sayfası yakında eklenecek'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          onLongPress: () => _setDefaultVehicle(vehicle),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Araç Emoji/İkon - iOS tarzı yuvarlak tasarım
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppDesign.primaryColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppDesign.primaryColor.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          classInfo['emoji']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Araç Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.brand} ${vehicle.model}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppDesign.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${vehicle.year} • ${vehicle.fuelType}',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppDesign.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Düzenle Butonu - iOS tarzı
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppDesign.primaryColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: () => _editVehicle(vehicle),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppDesign.primaryColor,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Detay Etiketleri - iOS tarzı chip'ler
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildInfoChip(
                      classInfo['name']!,
                      Icons.category_outlined,
                      Colors.blue,
                    ),
                    if (vehicle.isDefault == true)
                      _buildInfoChip(
                        'Varsayılan',
                        Icons.star,
                        Colors.amber,
                      ),
                    if (vehicle.color != null)
                      _buildInfoChip(
                        vehicle.color!,
                        Icons.palette_outlined,
                        Colors.purple,
                      ),
                    if (vehicle.plateNumber != null)
                      _buildInfoChip(
                        vehicle.plateNumber!,
                        Icons.pin_outlined,
                        Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editVehicle(VehicleModel vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: vehicle),
      ),
    );
    
    if (result == true) {
      _loadVehicles();
    }
  }

  Future<void> _setDefaultVehicle(VehicleModel vehicle) async {
    try {
      final userId = _firebaseService.currentUserId;
      if (userId == null) return;

      // Önce tüm araçların varsayılan ayarını kaldır
      final vehiclesSnapshot = await _firebaseService.userVehicles(userId).get();
      final batch = _firebaseService.firestore.batch();

      for (final doc in vehiclesSnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Seçilen aracı varsayılan yap
      batch.update(
        _firebaseService.userVehicles(userId).doc(vehicle.id),
        {'isDefault': true}
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.brand} ${vehicle.model} varsayılan araç olarak ayarlandı'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        _loadVehicles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

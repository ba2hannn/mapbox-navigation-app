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
          .orderBy('createdAt', descending: true)
          .get();

      final vehicles = snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();

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

  Future<void> _deleteVehicle(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aracı Sil'),
        content: Text(
          '${vehicle.brand} ${vehicle.model} aracını silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firebaseService
          .userVehicles(vehicle.userId)
          .doc(vehicle.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Araç silindi'),
            backgroundColor: Colors.green,
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppDesign.textPrimary),
        ),
        title: const Text(
          'Araçlarım',
          style: TextStyle(
            color: AppDesign.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
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
            icon: const Icon(Icons.add, color: AppDesign.primaryColor),
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicles[index];
                      return _buildVehicleCard(vehicle);
                    },
                  ),
                ),
      floatingActionButton: !_isLoading && _vehicles.isNotEmpty
          ? FloatingActionButton.extended(
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
              icon: const Icon(Icons.add),
              label: const Text('Yeni Araç'),
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
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppDesign.primaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_outlined,
              size: 60,
              color: AppDesign.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz araç eklemediniz',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Araç ekleyerek rota hesaplamalarınızı\ndaha hassas yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppDesign.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'İlk Aracınızı Ekleyin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Araç Emoji/İkon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppDesign.primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          classInfo['emoji']!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Araç Bilgileri
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.brand} ${vehicle.model}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${vehicle.year} • ${vehicle.fuelType}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppDesign.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sil Butonu
                    IconButton(
                      onPressed: () => _deleteVehicle(vehicle),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Detay Etiketleri
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      classInfo['name']!,
                      Icons.category_outlined,
                      Colors.blue,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

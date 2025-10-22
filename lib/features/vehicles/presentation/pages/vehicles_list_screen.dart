import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/animated_notification.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, size: 24),
        ),
        middle: const Text(
          'Araçlarım',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AddVehicleScreen(),
              ),
            );

            if (result == true) {
              _loadVehicles();
            }
          },
          child: const Icon(CupertinoIcons.add, size: 24),
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(),
            )
          : _vehicles.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: _loadVehicles,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final vehicle = _vehicles[index];
                            return _buildVehicleCard(vehicle);
                          },
                          childCount: _vehicles.length,
                        ),
                      ),
                    ),
                  ],
                ),
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
            child: const Icon(
              CupertinoIcons.car_detailed,
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
              color: CupertinoColors.label,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Araç ekleyerek rota hesaplamalarınızı\ndaha hassas yapabilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          CupertinoButton.filled(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AddVehicleScreen(),
                ),
              );

              if (result == true) {
                _loadVehicles();
              }
            },
            child: const Text(
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

    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.only(bottom: 16),
      children: [
        CupertinoListTile(
          title: Text('${vehicle.brand} ${vehicle.model}', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${vehicle.year} • ${vehicle.fuelType}'),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppDesign.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppDesign.primaryColor.withAlpha(30),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                classInfo['emoji']!,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vehicle.isDefault == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Varsayılan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _editVehicle(vehicle),
                child: const Icon(CupertinoIcons.pencil, size: 20),
              ),
            ],
          ),
          onTap: () {
            AnimatedNotification.showInfo(context, message: '🚧 Araç detay sayfası yakında eklenecek');
          },
        ),
      ],
    );
  }



  Future<void> _editVehicle(VehicleModel vehicle) async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AddVehicleScreen(vehicleToEdit: vehicle),
      ),
    );
    
    if (result == true) {
      _loadVehicles();
    }
  }


}

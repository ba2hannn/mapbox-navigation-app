import 'dart:convert';
import 'package:flutter/cupertino.dart'; // Material'dan Cupertino'ya geçildi
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar, Icons, LinearProgressIndicator, Colors; // Sadece gerekli olanlar bırakıldı
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/widgets/animated_notification.dart';
import '../../data/datasources/vehicle_data.dart';
import '../../data/models/vehicle_model.dart';
import '../../../vehicle/presentation/bloc/vehicle_bloc.dart';
import '../../../vehicle/presentation/bloc/vehicle_event.dart';
import '../../../vehicle/presentation/bloc/vehicle_state.dart';
import '../../../vehicle/domain/entities/vehicle_brand_entity.dart';
import '../../../vehicle/domain/entities/vehicle_model_entity.dart';
import '../../../vehicle/domain/entities/vehicle_entity.dart';

class AddVehicleScreen extends StatefulWidget {
  final VehicleModel? vehicleToEdit;

  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  // --- BACK-END VE STATE YÖNETİMİ (DEĞİŞTİRİLMEDİ) ---
  final _firebaseService = FirebaseService();
  bool _isSaving = false;
  bool get _isEditing => widget.vehicleToEdit != null;
  
  int _currentStep = 0;
  
  // Form verileri
  VehicleBrandEntity? _selectedBrand;
  VehicleModelEntity? _selectedModel;
  VehicleEntity? _selectedVehicle;
  int? _selectedYear;
  String? _selectedVehicleClass;
  String? _selectedFuelType;
  String? _selectedColor;
  final _plateController = TextEditingController();
  final _cityConsumptionController = TextEditingController();
  final _highwayConsumptionController = TextEditingController();

  // UI state
  List<VehicleBrandEntity> _brands = [];
  List<VehicleModelEntity> _models = [];
  List<VehicleEntity> _vehicles = [];
  bool _isLoadingBrands = false;
  bool _isLoadingModels = false;
  // --- SON: BACK-END VE STATE YÖNETİMİ ---

  @override
  void initState() {
    super.initState();
    _loadBrands();
    if (_isEditing) {
      _loadExistingVehicleData();
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _cityConsumptionController.dispose();
    _highwayConsumptionController.dispose();
    super.dispose();
  }

  // --- BLOC VE VERİ YÜKLEME METOTLARI (DEĞİŞTİRİLMEDİ) ---
  Future<void> _loadBrands() async {
    final bloc = context.read<VehicleBloc>();
    setState(() { _isLoadingBrands = true; });
    bloc.add(LoadBrands());
  }

  void _loadExistingVehicleData() {
    final vehicle = widget.vehicleToEdit!;
    _selectedYear = vehicle.year;
    _selectedVehicleClass = vehicle.vehicleClass;
    _selectedFuelType = vehicle.fuelType;
    _selectedColor = vehicle.color;
    _plateController.text = vehicle.plateNumber ?? '';
    _cityConsumptionController.text = vehicle.cityConsumption?.toString() ?? '';
    _highwayConsumptionController.text = vehicle.highwayConsumption?.toString() ?? '';
    _selectedBrand = null;
    _selectedModel = null;
    _selectedVehicle = null;
  }

  Future<void> _loadModels(String brandId) async {
    final bloc = context.read<VehicleBloc>();
    setState(() {
      _isLoadingModels = true;
      _models = [];
      _selectedModel = null;
      _vehicles = [];
      _selectedVehicle = null;
    });
    bloc.add(LoadModels(brandId));
  }

  Future<void> _loadVehicles(String modelId) async {
    final bloc = context.read<VehicleBloc>();
    setState(() {
      _vehicles = [];
      _selectedVehicle = null;
    });
    bloc.add(LoadVehicles(modelId));
  }
  
  List<VehicleModelEntity> _filterModels(List<VehicleModelEntity> models) {
    final filtered = models.where((model) {
      final name = model.name.toLowerCase();
      final cleanName = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '');
      final withoutVersions = cleanName.replaceAll(RegExp(r'\s+\d+\.\d+'), '');
      final finalName = withoutVersions
          .replaceAll(RegExp(r'\s+(cd|tdi|tdci|dci|mpi|mpi2|facelift|restyling|sport|comfort|classic|elegance|ambiente)\b'), '')
          .trim();
      return finalName.isNotEmpty;
    }).toList();
    
    final uniqueNames = <String>{};
    final uniqueModels = <VehicleModelEntity>[];
    
    for (final model in filtered) {
      final cleanName = model.name
          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
          .replaceAll(RegExp(r'\s+\d+\.\d+'), '')
          .replaceAll(RegExp(r'\s+(cd|tdi|tdci|dci|mpi|mpi2|facelift|restyling|sport|comfort|classic|elegance|ambiente)\b'), '')
          .trim();
      
      if (!uniqueNames.contains(cleanName) && cleanName.isNotEmpty) {
        uniqueNames.add(cleanName);
        uniqueModels.add(model);
      }
    }
    
    return uniqueModels.take(8).toList();
  }

  void _onBlocStateChanged(BuildContext context, VehicleState state) {
    if (state is BrandsLoaded) {
      setState(() {
        _brands = state.brands;
        _isLoadingBrands = false;
      });
    } else if (state is ModelsLoaded) {
      final filteredModels = _filterModels(state.models);
      setState(() {
        _models = filteredModels;
        _isLoadingModels = false;
      });
    } else if (state is VehiclesLoaded) {
      setState(() {
        _vehicles = state.vehicles;
      });
    } else if (state is VehicleError) {
      setState(() {
        _isLoadingBrands = false;
        _isLoadingModels = false;
      });
      _showErrorSnackBar(state.message);
    }
  }
  // --- SON: BLOC VE VERİ YÜKLEME METOTLARI ---

  // --- NAVİGASYON MANTIĞI (DEĞİŞTİRİLMEDİ) ---
  bool get _canGoNext {
    switch (_currentStep) {
      case 0: return _selectedBrand != null;
      case 1: return _selectedModel != null;
      case 2: return _selectedVehicle != null;
      case 3: return _selectedVehicleClass != null;
      case 4: return _selectedFuelType != null;
      case 5: return _selectedYear != null;
      case 6: return true;
      case 7: return true;
      default: return false;
    }
  }

  void _goToNextStep() {
    if (_canGoNext && _currentStep < 7) {
      if (_currentStep == 0 && _selectedBrand != null) {
        _loadModels(_selectedBrand!.id);
      } else if (_currentStep == 1 && _selectedModel != null) {
        _loadVehicles(_selectedModel!.id);
      }
      setState(() { _currentStep++; });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() { _currentStep--; });
    }
  }
  // --- SON: NAVİGASYON MANTIĞI ---

  // --- KAYDETME MANTIĞI (DEĞİŞTİRİLMEDİ) ---
  void _saveVehicle() async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) {
      _showErrorSnackBar('Lütfen giriş yapın');
      return;
    }

    setState(() { _isSaving = true; });

    try {
      final now = DateTime.now();
      
      if (_isEditing) {
        final updateData = {
          'year': _selectedYear,
          'vehicleClass': _selectedVehicleClass,
          'fuelType': _selectedFuelType,
          'color': _selectedColor,
          'plateNumber': _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
          'cityConsumption': _cityConsumptionController.text.trim().isEmpty ? null : double.tryParse(_cityConsumptionController.text.trim()),
          'highwayConsumption': _highwayConsumptionController.text.trim().isEmpty ? null : double.tryParse(_highwayConsumptionController.text.trim()),
          'updatedAt': now,
        };

        await _firebaseService.userVehicles(userId).doc(widget.vehicleToEdit!.id).update(updateData);
            
        final updatedVehicle = VehicleModel(
          id: widget.vehicleToEdit!.id,
          userId: widget.vehicleToEdit!.userId,
          brand: widget.vehicleToEdit!.brand,
          model: widget.vehicleToEdit!.model,
          year: _selectedYear ?? widget.vehicleToEdit!.year,
          vehicleClass: _selectedVehicleClass ?? widget.vehicleToEdit!.vehicleClass,
          fuelType: _selectedFuelType ?? widget.vehicleToEdit!.fuelType,
          color: _selectedColor ?? widget.vehicleToEdit!.color,
          plateNumber: _plateController.text.trim().isEmpty ? widget.vehicleToEdit!.plateNumber : _plateController.text.trim(),
          imageUrl: widget.vehicleToEdit!.imageUrl,
          createdAt: widget.vehicleToEdit!.createdAt,
          updatedAt: now,
          cityConsumption: _cityConsumptionController.text.trim().isEmpty ? widget.vehicleToEdit!.cityConsumption : double.tryParse(_cityConsumptionController.text.trim()),
          highwayConsumption: _highwayConsumptionController.text.trim().isEmpty ? widget.vehicleToEdit!.highwayConsumption : double.tryParse(_highwayConsumptionController.text.trim()),
          isDefault: widget.vehicleToEdit!.isDefault,
        );
        
        await _saveVehicleToLocal(updatedVehicle);
      } else {
        final vehicle = VehicleModel(
          id: '',
          userId: userId,
          brand: _selectedBrand!.name,
          model: _selectedModel!.name,
          year: _selectedYear!,
          vehicleClass: _selectedVehicleClass!,
          fuelType: _selectedFuelType!,
          color: _selectedColor,
          plateNumber: _plateController.text.trim().isEmpty ? null : _plateController.text.trim(),
          imageUrl: null,
          createdAt: now,
          updatedAt: now,
          cityConsumption: _cityConsumptionController.text.trim().isEmpty ? null : double.tryParse(_cityConsumptionController.text.trim()),
          highwayConsumption: _highwayConsumptionController.text.trim().isEmpty ? null : double.tryParse(_highwayConsumptionController.text.trim()),
          isDefault: false,
        );

        final docRef = await _firebaseService.userVehicles(userId).add(vehicle.toJson());
        
        final savedVehicle = vehicle.copyWith(id: docRef.id);
        
        await _saveVehicleToLocal(savedVehicle);
      }

      debugPrint('✅ Araç başarıyla ${_isEditing ? 'güncellendi' : 'kaydedildi'}!');
      
      if (mounted) {
        AnimatedNotification.showSuccess(context, message: _isEditing ? 'Araç güncellendi!' : '${_selectedBrand!.name} ${_selectedModel!.name} eklendi!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Araç ${_isEditing ? 'güncellenemedi' : 'kaydedilemedi'}: $e');
      if (mounted) {
        _showErrorSnackBar('Bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  Future<void> _saveVehicleToLocal(VehicleModel vehicle) async {
    // Bu metot değiştirilmedi
    try {
      final prefs = await SharedPreferences.getInstance();
      final vehicleJson = vehicle.toJson();
      final vehiclesJson = prefs.getStringList('vehicles') ?? [];
      final existingIndex = vehiclesJson.indexWhere((v) {
        try {
          final decoded = jsonDecode(v) as Map<String, dynamic>;
          return VehicleModel.fromJson(decoded).id == vehicle.id;
        } catch (e) { return false; }
      });
      
      if (existingIndex >= 0) {
        vehiclesJson[existingIndex] = jsonEncode(vehicleJson);
      } else {
        vehiclesJson.add(jsonEncode(vehicleJson));
      }
      
      await prefs.setStringList('vehicles', vehiclesJson);
      debugPrint('✅ Araç local storage\'a kaydedildi.');
    } catch (e) {
      debugPrint('❌ Araç local storage\'a kaydedilemedi: $e');
    }
  }
  // --- SON: KAYDETME MANTIĞI ---

  // --- YENİLENEN WIDGET'LAR ---
  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listener: _onBlocStateChanged,
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditing ? 'Araç Düzenle' : 'Araç Ekle'),
          previousPageTitle: 'Geri',
          // Kapatma butonu yerine iOS standardı olan 'Vazgeç' metni
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Vazgeç'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        child: Column(
          children: [
            // AppBar altına entegre edilmiş progress bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 8,
              backgroundColor: CupertinoColors.systemGrey5,
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.primaryColor),
              minHeight: 2,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _buildCurrentStep(),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildBrandStep();
      case 1: return _buildModelStep();
      case 2: return _buildVehicleStep();
      case 3: return _buildVehicleClassStep();
      case 4: return _buildFuelTypeStep();
      case 5: return _buildYearStep();
      case 6: return _buildPlateStep();
      case 7: return _buildConsumptionStep();
      default: return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  // Apple stili başlık
  Widget _buildStepHeader(String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADIM ${_currentStep + 1}/8',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: AppDesign.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
                color: CupertinoColors.label,
                fontSize: 28,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // ADIM 1: Marka Seçimi (CupertinoListSection ile)
  Widget _buildBrandStep() {
    if (_isLoadingBrands) {
      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()));
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Marka Seçin', 'Aracınızın markasını listeden bulun.'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final brand = _brands[index];
                final isSelected = _selectedBrand?.id == brand.id;
                return CupertinoListTile(
                  title: Text(brand.name, style: TextStyle(color: isSelected ? AppDesign.primaryColor : CupertinoColors.label)),
                  onTap: () {
                    setState(() {
                      _selectedBrand = brand;
                      _selectedModel = null;
                      _selectedVehicle = null;
                      _models = [];
                      _vehicles = [];
                    });
                    Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? AppDesign.primaryColor : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        brand.name[0],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppDesign.primaryColor)
                      : null,
                );
              },
              childCount: _brands.length,
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 2: Model Seçimi (Grid ve CupertinoButton ile)
  Widget _buildModelStep() {
     if (_isLoadingModels) {
      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()));
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Model Seçin', '${_selectedBrand?.name ?? ""} için bir model belirleyin.'),
         SliverPadding(
           padding: const EdgeInsets.symmetric(horizontal: 20),
           sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final model = _models[index];
                final isSelected = _selectedModel?.id == model.id;
                return CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _selectedModel = model;
                      _selectedVehicle = null;
                      _vehicles = [];
                    });
                    Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                  },
                  color: isSelected ? AppDesign.primaryColor : CupertinoColors.white,
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    model.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                    ),
                  ),
                );
              },
              childCount: _models.length,
            ),
                 ),
           ),
      ],
    );
  }

  // ADIM 3: Araç Seçimi (CupertinoListSection ile)
  Widget _buildVehicleStep() {
    if (_vehicles.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CupertinoActivityIndicator()));
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Araç Detayı', '${_selectedModel?.name ?? ""} için motor ve donanım seçin.'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _vehicles.map((vehicle) {
                  final isSelected = _selectedVehicle?.id == vehicle.id;
                  return Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CupertinoListTile(
                      title: Text(vehicle.modificationEngine, style: TextStyle(color: isSelected ? AppDesign.primaryColor : CupertinoColors.label)),
                      subtitle: Text('${vehicle.fuelConsumption.combined}L/100km • ${vehicle.yearRef}'),
                      onTap: () {
                        setState(() { _selectedVehicle = vehicle; });
                        Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                      },
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppDesign.primaryColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  // ADIM 4: Araç Sınıfı
  Widget _buildVehicleClassStep() {
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Araç Sınıfı', 'Geçiş ücreti hesaplamaları için gereklidir.'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: VehicleData.vehicleClasses.map((vehicleClass) {
                  final isSelected = _selectedVehicleClass == vehicleClass['id'];
                  return Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CupertinoListTile(
                      title: Text(vehicleClass['name']!, style: TextStyle(color: isSelected ? AppDesign.primaryColor : CupertinoColors.label)),
                      subtitle: Text(vehicleClass['description']!),
                      onTap: () {
                        setState(() { _selectedVehicleClass = vehicleClass['id']; });
                        Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                      },
                      leading: Text(vehicleClass['icon']!, style: const TextStyle(fontSize: 28)),
                      trailing: isSelected
                          ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppDesign.primaryColor)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 5: Yakıt Türü
  Widget _buildFuelTypeStep() {
    final icons = {
      'Benzin': CupertinoIcons.flame,
      'Dizel': CupertinoIcons.drop,
      'LPG': CupertinoIcons.circle_grid_3x3_fill,
      'Elektrik': CupertinoIcons.bolt_fill,
      'Hibrit': CupertinoIcons.leaf_arrow_circlepath,
    };

    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Yakıt Türü', 'Yakıt maliyeti hesaplamaları için gereklidir.'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fuelType = VehicleData.fuelTypes[index];
                final isSelected = _selectedFuelType == fuelType;
                return CupertinoButton(
                  onPressed: () {
                    setState(() { _selectedFuelType = fuelType; });
                    Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                  },
                  color: isSelected ? AppDesign.primaryColor : CupertinoColors.white,
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[fuelType], size: 28, color: isSelected ? CupertinoColors.white : CupertinoColors.secondaryLabel),
                      const SizedBox(height: 8),
                      Text(
                        fuelType,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: VehicleData.fuelTypes.length,
            ),
          ),
        )
      ],
    );
  }

  // ADIM 6: Yıl Seçimi
  Widget _buildYearStep() {
    final years = VehicleData.years;
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Model Yılı', 'Aracınızın üretildiği yılı seçin.'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final year = years[index];
                final isSelected = _selectedYear == year;
                return CupertinoButton(
                  onPressed: () {
                    setState(() { _selectedYear = year; });
                    Future.delayed(const Duration(milliseconds: 200), _goToNextStep);
                  },
                  color: isSelected ? AppDesign.primaryColor : CupertinoColors.white,
                  padding: const EdgeInsets.all(8),
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    year.toString(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? CupertinoColors.white : CupertinoColors.label,
                    ),
                  ),
                );
              },
              childCount: years.length,
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 7: Plaka (CupertinoTextField ile)
  Widget _buildPlateStep() {
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Plaka (Opsiyonel)', 'Plaka bilginizi sadece siz görebilirsiniz.'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CupertinoTextField(
              controller: _plateController,
              placeholder: '34 ABC 123',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Icon(CupertinoIcons.car_detailed, color: CupertinoColors.systemGrey),
              ),
              textCapitalization: TextCapitalization.characters,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // ADIM 8: Tüketim (CupertinoTextField ile)
  Widget _buildConsumptionStep() {
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Tüketim (Opsiyonel)', 'Daha doğru maliyet hesaplamaları için.'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'TÜKETİM (L/100KM)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CupertinoTextField.borderless(
                      controller: _cityConsumptionController,
                      placeholder: 'Şehir İçi (örn: 8.5)',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Icon(CupertinoIcons.building_2_fill, color: CupertinoColors.systemGrey),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: CupertinoTextField.borderless(
                      controller: _highwayConsumptionController,
                      placeholder: 'Şehir Dışı (örn: 6.2)',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 12.0),
                        child: Icon(CupertinoIcons.bold, color: CupertinoColors.systemGrey),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Apple stili alt buton barı
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CupertinoButton(
                onPressed: _goToPreviousStep,
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: CupertinoButton.filled(
              onPressed: _isSaving ? null : (_currentStep == 7 ? _saveVehicle : (_canGoNext ? _goToNextStep : null)),
              borderRadius: BorderRadius.circular(12),
              child: _isSaving
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Text(
                      _currentStep == 7 ? 'Kaydet' : 'Devam',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Apple stili SnackBar alternatifleri
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message))]),
      backgroundColor: Colors.red,
    ));
  }
}

// VehicleModel'a eklenmesi önerilen yardımcı metot
extension VehicleModelCopy on VehicleModel {
  VehicleModel copyWith({String? id}) {
    return VehicleModel(
      id: id ?? this.id,
      userId: userId,
      brand: brand,
      model: model,
      year: year,
      vehicleClass: vehicleClass,
      fuelType: fuelType,
      plateNumber: plateNumber,
      color: color,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cityConsumption: cityConsumption,
      highwayConsumption: highwayConsumption,
      isDefault: isDefault,
    );
  }
}
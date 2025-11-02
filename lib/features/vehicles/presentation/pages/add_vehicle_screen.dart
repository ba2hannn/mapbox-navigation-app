import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        NotificationHelper.show(context, _isEditing ? 'Araç güncellendi!' : '${_selectedBrand!.name} ${_selectedModel!.name} eklendi!');
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

  // --- APPLE-LIKE MODERN WIDGET'LAR ---
  @override
  Widget build(BuildContext context) {
    return BlocListener<VehicleBloc, VehicleState>(
      listener: _onBlocStateChanged,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Colors.white.withOpacity(0.8),
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Araç Düzenle' : 'Araç Ekle',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adım ${_currentStep + 1} / 8',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppDesign.primaryColor,
                          AppDesign.primaryColor.withOpacity(0.5),
                        ],
                        stops: [(_currentStep + 1) / 8, (_currentStep + 1) / 8],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  _buildCurrentStep(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildModernBottomBar(),
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

  // Modern Apple-like başlık
  Widget _buildStepHeader(String title, String subtitle, {IconData? icon}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppDesign.primaryColor.withOpacity(0.15),
                      AppDesign.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppDesign.primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 32, color: AppDesign.primaryColor),
              ),
            SizedBox(height: icon != null ? 20 : 0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // ADIM 1: Marka Seçimi - Modern Glass Cards
  Widget _buildBrandStep() {
    if (_isLoadingBrands) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppDesign.primaryColor),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Marka Seçin', 'Aracınızın markasını listeden bulun.', icon: Icons.business_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final brand = _brands[index];
                final isSelected = _selectedBrand?.id == brand.id;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppDesign.primaryColor.withOpacity(0.1)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? AppDesign.primaryColor.withOpacity(0.5)
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppDesign.primaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ] : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBrand = brand;
                            _selectedModel = null;
                            _selectedVehicle = null;
                            _models = [];
                            _vehicles = [];
                          });
                          Future.delayed(const Duration(milliseconds: 300), _goToNextStep);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [AppDesign.primaryColor, AppDesign.primaryColor.withOpacity(0.7)]
                                        : [Colors.grey.shade200, Colors.grey.shade300],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppDesign.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : [],
                                ),
                                child: Center(
                                  child: Text(
                                    brand.name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppDesign.primaryColor : Colors.black87,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppDesign.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppDesign.primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _brands.length,
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 2: Model Seçimi - Modern Glass Grid
  Widget _buildModelStep() {
    if (_isLoadingModels) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppDesign.primaryColor),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Model Seçin', '${_selectedBrand?.name ?? ""} için bir model belirleyin.', icon: Icons.directions_car_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final model = _models[index];
                final isSelected = _selectedModel?.id == model.id;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 30)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedModel = model;
                          _selectedVehicle = null;
                          _vehicles = [];
                        });
                        Future.delayed(const Duration(milliseconds: 300), _goToNextStep);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppDesign.primaryColor,
                                    AppDesign.primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? AppDesign.primaryColor.withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppDesign.primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Center(
                          child: Text(
                            model.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
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
      return SliverFillRemaining(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryColor),
            ),
          ),
        ),
      );
    }
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Araç Detayı', '${_selectedModel?.name ?? ""} için motor ve donanım seçin.', icon: Icons.build_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final vehicle = _vehicles[index];
                final isSelected = _selectedVehicle?.id == vehicle.id;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 250 + (index * 60)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(30 * (1 - value), 0),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppDesign.primaryColor.withOpacity(0.15),
                                AppDesign.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected 
                            ? AppDesign.primaryColor.withOpacity(0.5) 
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppDesign.primaryColor.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ] : [
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
                          setState(() { _selectedVehicle = vehicle; });
                          Future.delayed(const Duration(milliseconds: 250), _goToNextStep);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isSelected 
                                        ? [AppDesign.primaryColor, AppDesign.primaryColor.withOpacity(0.7)]
                                        : [Colors.grey.shade400, Colors.grey.shade300],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected ? AppDesign.primaryColor : Colors.grey).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.settings_outlined,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicle.modificationEngine,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppDesign.primaryColor : Colors.black87,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_gas_station_rounded, size: 12, color: Color(0xFFFF6B6B)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${vehicle.fuelConsumption.combined}L',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFFF6B6B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4ECDC4).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF4ECDC4)),
                                              const SizedBox(width: 4),
                                              Text(
                                                vehicle.yearRef,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF4ECDC4),
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
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppDesign.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppDesign.primaryColor.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _vehicles.length,
            ),
          ),
        )
      ],
    );
  }

  // ADIM 4: Araç Sınıfı - Modern Glass List
  Widget _buildVehicleClassStep() {
    final classColors = {
      '1': const Color(0xFF4CAF50),
      '2': const Color(0xFF2196F3),
      '3': const Color(0xFFFF9800),
      '4': const Color(0xFFF44336),
      '5': const Color(0xFF9C27B0),
    };
    
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Araç Sınıfı', 'Geçiş ücreti hesaplamaları için gereklidir.', icon: Icons.category_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final vehicleClass = VehicleData.vehicleClasses[index];
                final isSelected = _selectedVehicleClass == vehicleClass['id'];
                final color = classColors[vehicleClass['id']] ?? Colors.grey;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 70)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                color.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ] : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() { _selectedVehicleClass = vehicleClass['id']; });
                          Future.delayed(const Duration(milliseconds: 300), _goToNextStep);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withOpacity(0.7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    vehicleClass['icon']!,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicleClass['name']!,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? color : Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vehicleClass['description']!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: VehicleData.vehicleClasses.length,
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 5: Yakıt Türü - Modern Icons
  Widget _buildFuelTypeStep() {
    final fuelData = {
      'Benzin': {'icon': Icons.local_gas_station_rounded, 'color': const Color(0xFFFF6B6B)},
      'Dizel': {'icon': Icons.water_drop_rounded, 'color': const Color(0xFF4ECDC4)},
      'LPG': {'icon': Icons.propane_tank_rounded, 'color': const Color(0xFF95E1D3)},
      'Elektrik': {'icon': Icons.electric_bolt_rounded, 'color': const Color(0xFFFECA57)},
      'Hibrit': {'icon': Icons.eco_rounded, 'color': const Color(0xFF48C774)},
    };

    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Yakıt Türü', 'Yakıt maliyeti hesaplamaları için gereklidir.', icon: Icons.local_gas_station_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fuelType = VehicleData.fuelTypes[index];
                final isSelected = _selectedFuelType == fuelType;
                final data = fuelData[fuelType]!;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() { _selectedFuelType = fuelType; });
                        Future.delayed(const Duration(milliseconds: 300), _goToNextStep);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    data['color'] as Color,
                                    (data['color'] as Color).withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? (data['color'] as Color).withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: (data['color'] as Color).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ] : [],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              data['icon'] as IconData,
                              size: 40,
                              color: isSelected ? Colors.white : (data['color'] as Color),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fuelType,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: VehicleData.fuelTypes.length,
            ),
          ),
        ),
      ],
    );
  }

  // ADIM 6: Yıl Seçimi - Modern Chips
  Widget _buildYearStep() {
    final years = VehicleData.years;
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Model Yılı', 'Aracınızın üretildiği yılı seçin.', icon: Icons.calendar_today_rounded),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final year = years[index];
                final isSelected = _selectedYear == year;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 200 + (index * 20)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() { _selectedYear = year; });
                        Future.delayed(const Duration(milliseconds: 250), _goToNextStep);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    AppDesign.primaryColor,
                                    AppDesign.primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected 
                                ? AppDesign.primaryColor.withOpacity(0.5)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppDesign.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
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

  // ADIM 7: Plaka - Modern Glass Input
  Widget _buildPlateStep() {
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Plaka (Opsiyonel)', 'Plaka bilginizi sadece siz görebilirsiniz.', icon: Icons.credit_card_rounded),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '34 ABC 123',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.directions_car_rounded,
                    color: AppDesign.primaryColor,
                    size: 28,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // ADIM 8: Tüketim - Modern Glass Inputs
  Widget _buildConsumptionStep() {
    return SliverMainAxisGroup(
      slivers: [
        _buildStepHeader('Tüketim (Opsiyonel)', 'Daha doğru maliyet hesaplamaları için.', icon: Icons.speed_rounded),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Şehir İçi
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _cityConsumptionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Şehir İçi',
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: '8.5',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: Color(0xFFFF6B6B),
                          size: 24,
                        ),
                      ),
                      suffixText: 'L/100km',
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                
                // Şehir Dışı
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _highwayConsumptionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Şehir Dışı',
                      labelStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      hintText: '6.2',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                      ),
                      suffixText: 'L/100km',
                      suffixStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Modern Apple-like glassmorphic bottom bar
  Widget _buildModernBottomBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: _buildGlassButton(
                      onPressed: _goToPreviousStep,
                      label: 'Geri',
                      icon: Icons.arrow_back_ios_rounded,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: _currentStep > 0 ? 2 : 1,
                  child: _buildGlassButton(
                    onPressed: _isSaving ? null : (_currentStep == 7 ? _saveVehicle : (_canGoNext ? _goToNextStep : null)),
                    label: _isSaving ? 'Kaydediliyor...' : (_currentStep == 7 ? 'Kaydet' : 'Devam'),
                    icon: _currentStep == 7 ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
                    isPrimary: true,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    final isDisabled = onPressed == null;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary && !isDisabled ? [
          BoxShadow(
            color: AppDesign.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: isDisabled
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : [AppDesign.primaryColor, AppDesign.primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary ? null : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: isPrimary ? null : Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isPrimary && !isLoading)
                  Icon(icon, size: 18, color: Colors.grey.shade700),
                if (!isPrimary && !isLoading) const SizedBox(width: 8),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? Colors.white : AppDesign.primaryColor,
                      ),
                    ),
                  )
                else
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isPrimary ? Colors.white : Colors.grey.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                if (isPrimary && !isLoading) const SizedBox(width: 8),
                if (isPrimary && !isLoading)
                  Icon(icon, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Modern bildirim helper'ı
  void _showErrorSnackBar(String message) {
    NotificationHelper.show(
      context,
      message,
      isError: true,
    );
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
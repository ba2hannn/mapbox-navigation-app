import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/datasources/vehicle_data.dart';
import '../../data/models/vehicle_model.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _firebaseService = FirebaseService();
  bool _isSaving = false;
  
  int _currentStep = 0;
  
  // Form verileri
  String? _selectedBrand;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedVehicleClass;
  String? _selectedFuelType;
  String? _selectedColor;
  final _plateController = TextEditingController();

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    switch (_currentStep) {
      case 0: // Marka
        return _selectedBrand != null;
      case 1: // Model
        return _selectedModel != null;
      case 2: // Yıl
        return _selectedYear != null;
      case 3: // Araç Sınıfı
        return _selectedVehicleClass != null;
      case 4: // Yakıt Türü
        return _selectedFuelType != null;
      case 5: // Renk (opsiyonel)
        return true;
      case 6: // Plaka (opsiyonel)
        return true;
      default:
        return false;
    }
  }

  void _goToNextStep() {
    if (_canGoNext && _currentStep < 6) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _saveVehicle() async {
    // Kullanıcı ID'sini kontrol et
    final userId = _firebaseService.currentUserId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen giriş yapın'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();
      final vehicle = VehicleModel(
        id: '', // Firestore otomatik oluşturacak
        userId: userId,
        brand: _selectedBrand!,
        model: _selectedModel!,
        year: _selectedYear!,
        vehicleClass: _selectedVehicleClass!,
        fuelType: _selectedFuelType!,
        color: _selectedColor,
        plateNumber: _plateController.text.trim().isEmpty 
            ? null 
            : _plateController.text.trim(),
        imageUrl: null,
        createdAt: now,
        updatedAt: now,
      );

      // Firebase'e kaydet
      final docRef = await _firebaseService
          .userVehicles(userId)
          .add(vehicle.toJson());

      debugPrint('✅ Araç başarıyla kaydedildi! ID: ${docRef.id}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_selectedBrand $_selectedModel başarıyla eklendi!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true); // true = araç eklendi
      }
    } catch (e) {
      debugPrint('❌ Araç kaydedilemedi: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hata: $e',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          icon: const Icon(Icons.close, color: AppDesign.textPrimary),
        ),
        title: const Text(
          'Araç Ekle',
          style: TextStyle(
            color: AppDesign.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 7,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.primaryColor),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBrandStep();
      case 1:
        return _buildModelStep();
      case 2:
        return _buildYearStep();
      case 3:
        return _buildVehicleClassStep();
      case 4:
        return _buildFuelTypeStep();
      case 5:
        return _buildColorStep();
      case 6:
        return _buildPlateStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adım ${_currentStep + 1}/7',
            style: TextStyle(
              fontSize: 14,
              color: AppDesign.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppDesign.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppDesign.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ADIM 1: Marka Seçimi
  Widget _buildBrandStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Marka Seçin', 'Aracınızın markasını seçin'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: VehicleData.brands.length,
            itemBuilder: (context, index) {
              final brand = VehicleData.brands[index];
              final isSelected = _selectedBrand == brand;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBrand = brand;
                        _selectedModel = null; // Reset model
                      });
                      Future.delayed(const Duration(milliseconds: 200), () {
                        _goToNextStep();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppDesign.primaryColor.withAlpha(25)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppDesign.primaryColor
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppDesign.primaryColor
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                brand[0],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppDesign.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              brand,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? AppDesign.primaryColor
                                    : AppDesign.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppDesign.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 2: Model Seçimi
  Widget _buildModelStep() {
    final models = VehicleData.getModelsForBrand(_selectedBrand ?? '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Model Seçin', '$_selectedBrand modeli seçin'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              final isSelected = _selectedModel == model;
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedModel = model;
                    });
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _goToNextStep();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppDesign.primaryColor.withAlpha(25)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppDesign.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        model,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppDesign.primaryColor
                              : AppDesign.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 3: Yıl Seçimi
  Widget _buildYearStep() {
    final years = VehicleData.years;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Model Yılı', 'Aracınızın üretim yılını seçin'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
            ),
            itemCount: years.length,
            itemBuilder: (context, index) {
              final year = years[index];
              final isSelected = _selectedYear == year;
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedYear = year;
                    });
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _goToNextStep();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppDesign.primaryColor
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppDesign.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppDesign.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 4: Araç Sınıfı (HGS/OGS)
  Widget _buildVehicleClassStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Araç Sınıfı', 'Geçiş ücreti hesaplama için'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: VehicleData.vehicleClasses.length,
            itemBuilder: (context, index) {
              final vehicleClass = VehicleData.vehicleClasses[index];
              final isSelected = _selectedVehicleClass == vehicleClass['id'];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedVehicleClass = vehicleClass['id'];
                      });
                      Future.delayed(const Duration(milliseconds: 200), () {
                        _goToNextStep();
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppDesign.primaryColor.withAlpha(25)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppDesign.primaryColor
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            vehicleClass['icon']!,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicleClass['name']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppDesign.primaryColor
                                        : AppDesign.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicleClass['description']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppDesign.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppDesign.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 5: Yakıt Türü
  Widget _buildFuelTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Yakıt Türü', 'Yakıt tüketimi hesaplama için'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
            ),
            itemCount: VehicleData.fuelTypes.length,
            itemBuilder: (context, index) {
              final fuelType = VehicleData.fuelTypes[index];
              final isSelected = _selectedFuelType == fuelType;
              
              final icons = {
                'Benzin': Icons.local_gas_station,
                'Dizel': Icons.oil_barrel,
                'LPG': Icons.propane_tank,
                'Elektrik': Icons.electric_bolt,
                'Hibrit': Icons.electric_car,
              };
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFuelType = fuelType;
                    });
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _goToNextStep();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppDesign.primaryColor.withAlpha(25)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppDesign.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[fuelType],
                          size: 32,
                          color: isSelected
                              ? AppDesign.primaryColor
                              : AppDesign.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fuelType,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppDesign.primaryColor
                                : AppDesign.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 6: Renk (Opsiyonel)
  Widget _buildColorStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Renk (Opsiyonel)', 'Aracınızın rengini seçin'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: VehicleData.colors.length,
            itemBuilder: (context, index) {
              final colorData = VehicleData.colors[index];
              final colorName = colorData['name'] as String;
              final colorHex = colorData['hex'] as String;
              final isSelected = _selectedColor == colorName;
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorName;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppDesign.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(colorHex.substring(1), radix: 16) +
                                  0xFF000000,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: colorName == 'Beyaz'
                                      ? Colors.black
                                      : Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          colorName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppDesign.primaryColor
                                : AppDesign.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ADIM 7: Plaka (Opsiyonel)
  Widget _buildPlateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Plaka (Opsiyonel)', 'Plaka numaranızı girin'),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: '34 ABC 123',
                  prefixIcon: const Icon(Icons.pin),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: AppDesign.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Plaka bilgisi opsiyoneldir ve sadece sizin görebilmeniz için kaydedilir.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Geri'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving 
                  ? null 
                  : (_currentStep == 6 ? _saveVehicle : (_canGoNext ? _goToNextStep : null)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesign.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 6 ? 'Kaydet' : 'Devam',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import '../../../../core/services/firebase_service.dart';
import '../models/vehicle_model.dart';

class VehicleRemoteDataSource {
  final FirebaseService _firebaseService;

  VehicleRemoteDataSource(this._firebaseService);

  // Kullanıcının araçlarını getir
  Future<List<VehicleModel>> getUserVehicles(String userId) async {
    try {
      final snapshot =
          await _firebaseService.userVehicles(userId).orderBy('createdAt', descending: true).get();
      
      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Araçlar yüklenemedi: $e');
    }
  }

  // Araç ekle
  Future<VehicleModel> addVehicle(VehicleModel vehicle) async {
    try {
      final docRef = await _firebaseService
          .userVehicles(vehicle.userId)
          .add(vehicle.toJson());
      
      final doc = await docRef.get();
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Araç eklenemedi: $e');
    }
  }

  // Araç güncelle
  Future<void> updateVehicle(VehicleModel vehicle) async {
    try {
      await _firebaseService
          .userVehicles(vehicle.userId)
          .doc(vehicle.id)
          .update(vehicle.toJson());
    } catch (e) {
      throw Exception('Araç güncellenemedi: $e');
    }
  }

  // Araç sil
  Future<void> deleteVehicle(String userId, String vehicleId) async {
    try {
      await _firebaseService
          .userVehicles(userId)
          .doc(vehicleId)
          .delete();
    } catch (e) {
      throw Exception('Araç silinemedi: $e');
    }
  }

  // Tek araç getir
  Future<VehicleModel?> getVehicle(String userId, String vehicleId) async {
    try {
      final doc = await _firebaseService
          .userVehicles(userId)
          .doc(vehicleId)
          .get();
      
      if (doc.exists) {
        return VehicleModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Araç bulunamadı: $e');
    }
  }
}

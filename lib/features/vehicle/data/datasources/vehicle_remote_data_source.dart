// Path: lib/features/vehicle/data/datasources/vehicle_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/vehicle_brand_model.dart';
import '../models/vehicle_model_model.dart';
import '../models/vehicle_model.dart';
import '../models/year_model.dart';
import '../models/body_type_model.dart';

abstract class VehicleRemoteDataSource {
  // Yeni Firebase yapısı için
  Future<List<VehicleBrandModel>> getAllBrands();
  Future<List<VehicleModelModel>> getModelsByBrand(String brandId);
  Future<List<VehicleModel>> getVehiclesByModel(String modelId);
  Future<List<YearModel>> getYearsByModel(String modelId);
  Future<List<BodyTypeModel>> getBodyTypesByModelAndYear(String modelId, String year);
  Future<VehicleModel?> getVehicleById(String vehicleId);

  // Eski yapı için backward compatibility
  Future<List<VehicleModel>> getAllVehicles();
  Future<VehicleModel> getVehicleByIdOld(String id);
}

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final FirebaseFirestore firestore;

  VehicleRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<VehicleBrandModel>> getAllBrands() async {
    try {
      final snapshot = await firestore.collection('brands').get();
      return snapshot.docs
          .map((doc) => VehicleBrandModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<VehicleModelModel>> getModelsByBrand(String brandId) async {
    try {
      final snapshot = await firestore
          .collection('models')
          .where('brand_ref', isEqualTo: 'brands/$brandId')
          .get();
      return snapshot.docs
          .map((doc) => VehicleModelModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<VehicleModel>> getVehiclesByModel(String modelId) async {
    try {
      final snapshot = await firestore
          .collection('cars')
          .where('model_ref', isEqualTo: 'models/$modelId')
          .get();
      return snapshot.docs
          .map((doc) => VehicleModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<YearModel>> getYearsByModel(String modelId) async {
    try {
      final snapshot = await firestore
          .collection('cars')
          .where('model_ref', isEqualTo: 'models/$modelId')
          .get();

      // Extract unique years from cars
      final years = <String>{};
      for (final doc in snapshot.docs) {
        final yearRef = doc.data()['year_ref'] as String?;
        if (yearRef != null) {
          // Extract year value from year_ref (assuming format: 'years/2010')
          final yearValue = yearRef.split('/').last;
          years.add(yearValue);
        }
      }

      return years.map((year) => YearModel(id: year, value: year)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<BodyTypeModel>> getBodyTypesByModelAndYear(String modelId, String year) async {
    try {
      final snapshot = await firestore
          .collection('cars')
          .where('model_ref', isEqualTo: 'models/$modelId')
          .where('year_ref', isEqualTo: 'years/$year')
          .get();

      // Extract unique body types from cars
      final bodyTypes = <String>{};
      for (final doc in snapshot.docs) {
        final bodyTypeRef = doc.data()['body_type_ref'] as String?;
        if (bodyTypeRef != null) {
          // Extract body type value from body_type_ref (assuming format: 'body_types/hatchback')
          final bodyTypeValue = bodyTypeRef.split('/').last;
          bodyTypes.add(bodyTypeValue);
        }
      }

      return bodyTypes.map((bodyType) => BodyTypeModel(id: bodyType, value: bodyType)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await firestore.collection('cars').doc(vehicleId).get();
      if (doc.exists) {
        return VehicleModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw ServerException();
    }
  }

  // Eski yapı için backward compatibility
  @override
  Future<List<VehicleModel>> getAllVehicles() async {
    try {
      final snapshot = await firestore.collection('vehicles').get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) => VehicleModel.fromSnapshot(doc)).toList();
    } catch (e) {
      throw ServerException(message: "Araç verileri alınamadı: $e");
    }
  }

  @override
  Future<VehicleModel> getVehicleByIdOld(String id) async {
    try {
      final doc = await firestore.collection('vehicles').doc(id).get();

      if (!doc.exists) {
        throw NotFoundException(message: "Araç bulunamadı: $id");
      }

      return VehicleModel.fromSnapshot(doc);
    } catch (e) {
      if (e is NotFoundException) rethrow;
      throw ServerException(message: "Araç verisi alınamadı: $e");
    }
  }
}
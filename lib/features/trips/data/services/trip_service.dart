import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Yeni bir yolculuk başlatır
  Future<String> startTrip({
    required String userId,
    required String vehicleId,
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required double estimatedDistanceKm,
  }) async {
    final trip = Trip(
      id: '', // Firestore otomatik oluşturacak
      userId: userId,
      vehicleId: vehicleId,
      startTime: DateTime.now(),
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      distanceKm: estimatedDistanceKm,
    );

    final docRef = await _firestore.collection('trips').add(trip.toFirestore());
    return docRef.id;
  }

  /// Yolculuğu tamamlar ve gerçek verileri kaydeder
  Future<void> completeTrip({
    required String tripId,
    double? actualConsumption,
    double? fuelUsed,
    double? fuelCost,
    double? tollCost,
    int? trafficLevel,
    double? elevationGain,
    String? notes,
  }) async {
    final updateData = <String, dynamic>{
      'endTime': Timestamp.fromDate(DateTime.now()),
      'isCompleted': true,
    };

    if (actualConsumption != null) updateData['actualConsumption'] = actualConsumption;
    if (fuelUsed != null) updateData['fuelUsed'] = fuelUsed;
    if (fuelCost != null) updateData['fuelCost'] = fuelCost;
    if (tollCost != null) updateData['tollCost'] = tollCost;
    if (trafficLevel != null) updateData['trafficLevel'] = trafficLevel;
    if (elevationGain != null) updateData['elevationGain'] = elevationGain;
    if (notes != null) updateData['notes'] = notes;

    await _firestore.collection('trips').doc(tripId).update(updateData);
  }

  /// Kullanıcının yolculuklarını getirir
  Future<List<Trip>> getUserTrips(String userId, {int limit = 50}) async {
    final querySnapshot = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  /// Belirli bir aracın yolculuklarını getirir
  Future<List<Trip>> getVehicleTrips(String vehicleId, {int limit = 20}) async {
    final querySnapshot = await _firestore
        .collection('trips')
        .where('vehicleId', isEqualTo: vehicleId)
        .limit(limit * 2) // Fazla al ki filtreledikten sonra yeterli kalır
        .get();

    // Sadece tamamlanmış yolculukları filtrele ve tarihe göre sırala
    final completedTrips = querySnapshot.docs
        .map((doc) => Trip.fromFirestore(doc))
        .where((trip) => trip.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Manuel sıralama

    return completedTrips.take(limit).toList();
  }

  /// Bir aracın ortalama tüketimini hesaplar
  Future<double?> getAverageConsumption(String vehicleId) async {
    final trips = await getVehicleTrips(vehicleId);

    if (trips.isEmpty) return null;

    // Sadece gerçek tüketim verisi olan yolculukları al
    final tripsWithConsumption = trips.where((trip) =>
      trip.actualConsumption != null && trip.actualConsumption! > 0
    ).toList();

    if (tripsWithConsumption.isEmpty) return null;

    // Ağırlıklı ortalama hesapla (daha uzun yolculuklar daha güvenilir)
    double totalWeightedConsumption = 0.0;
    double totalWeight = 0.0;

    for (final trip in tripsWithConsumption) {
      final weight = trip.distanceKm; // Mesafe ağırlık olarak kullanılır
      totalWeightedConsumption += trip.actualConsumption! * weight;
      totalWeight += weight;
    }

    return totalWeightedConsumption / totalWeight;
  }

  /// Bir aracın tüketim istatistiklerini getirir
  Future<VehicleConsumptionStats> getVehicleConsumptionStats(String vehicleId) async {
    final trips = await getVehicleTrips(vehicleId);

    if (trips.isEmpty) {
      return VehicleConsumptionStats.empty();
    }

    final completedTrips = trips.where((t) => t.isCompleted).toList();
    final tripsWithConsumption = completedTrips.where((t) =>
      t.actualConsumption != null && t.actualConsumption! > 0
    ).toList();

    if (tripsWithConsumption.isEmpty) {
      return VehicleConsumptionStats(
        totalTrips: completedTrips.length,
        tripsWithConsumption: 0,
        averageConsumption: null,
        minConsumption: null,
        maxConsumption: null,
        totalDistance: completedTrips.fold(0.0, (total, t) => total + t.distanceKm),
        totalFuelUsed: null,
      );
    }

    final consumptions = tripsWithConsumption.map((t) => t.actualConsumption!).toList();
    final averageConsumption = await getAverageConsumption(vehicleId);
    final totalFuelUsed = tripsWithConsumption.fold(0.0, (total, t) => total + (t.fuelUsed ?? 0));

    return VehicleConsumptionStats(
      totalTrips: completedTrips.length,
      tripsWithConsumption: tripsWithConsumption.length,
      averageConsumption: averageConsumption,
      minConsumption: consumptions.reduce((a, b) => a < b ? a : b),
      maxConsumption: consumptions.reduce((a, b) => a > b ? a : b),
      totalDistance: completedTrips.fold(0.0, (total, t) => total + t.distanceKm),
      totalFuelUsed: totalFuelUsed > 0 ? totalFuelUsed : null,
    );
  }

  /// Devam eden yolculukları getirir
  Future<List<Trip>> getOngoingTrips(String userId) async {
    final querySnapshot = await _firestore
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('startTime', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  /// Yolculuğu siler
  Future<void> deleteTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).delete();
  }
}

class VehicleConsumptionStats {
  final int totalTrips;
  final int tripsWithConsumption;
  final double? averageConsumption;
  final double? minConsumption;
  final double? maxConsumption;
  final double totalDistance;
  final double? totalFuelUsed;

  VehicleConsumptionStats({
    required this.totalTrips,
    required this.tripsWithConsumption,
    this.averageConsumption,
    this.minConsumption,
    this.maxConsumption,
    required this.totalDistance,
    this.totalFuelUsed,
  });

  factory VehicleConsumptionStats.empty() {
    return VehicleConsumptionStats(
      totalTrips: 0,
      tripsWithConsumption: 0,
      totalDistance: 0.0,
    );
  }

  String get averageConsumptionText {
    if (averageConsumption == null) return '—';
    return '${averageConsumption!.toStringAsFixed(1)} L/100km';
  }

  String get totalDistanceText {
    if (totalDistance < 1) return '${(totalDistance * 1000).toInt()} m';
    return '${totalDistance.toStringAsFixed(1)} km';
  }

  String get totalFuelUsedText {
    if (totalFuelUsed == null) return '—';
    return '${totalFuelUsed!.toStringAsFixed(1)} L';
  }
}
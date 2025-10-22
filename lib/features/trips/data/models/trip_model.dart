import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String userId;
  final String vehicleId;
  final DateTime startTime;
  final DateTime? endTime;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double distanceKm;
  final double? actualConsumption; // L/100km
  final double? fuelUsed; // litre
  final double? fuelCost; // TL
  final int? trafficLevel; // 0-10
  final double? elevationGain; // metre
  final String? notes;
  final bool isCompleted;

  Trip({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.startTime,
    this.endTime,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distanceKm,
    this.actualConsumption,
    this.fuelUsed,
    this.fuelCost,
    this.trafficLevel,
    this.elevationGain,
    this.notes,
    this.isCompleted = false,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      startLat: (data['startLat'] as num).toDouble(),
      startLng: (data['startLng'] as num).toDouble(),
      endLat: (data['endLat'] as num).toDouble(),
      endLng: (data['endLng'] as num).toDouble(),
      distanceKm: (data['distanceKm'] as num).toDouble(),
      actualConsumption: data['actualConsumption'] != null ? (data['actualConsumption'] as num).toDouble() : null,
      fuelUsed: data['fuelUsed'] != null ? (data['fuelUsed'] as num).toDouble() : null,
      fuelCost: data['fuelCost'] != null ? (data['fuelCost'] as num).toDouble() : null,
      trafficLevel: data['trafficLevel'],
      elevationGain: data['elevationGain'] != null ? (data['elevationGain'] as num).toDouble() : null,
      notes: data['notes'],
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'vehicleId': vehicleId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distanceKm': distanceKm,
      'actualConsumption': actualConsumption,
      'fuelUsed': fuelUsed,
      'fuelCost': fuelCost,
      'trafficLevel': trafficLevel,
      'elevationGain': elevationGain,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  Trip copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    DateTime? startTime,
    DateTime? endTime,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? distanceKm,
    double? actualConsumption,
    double? fuelUsed,
    double? fuelCost,
    int? trafficLevel,
    double? elevationGain,
    String? notes,
    bool? isCompleted,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      distanceKm: distanceKm ?? this.distanceKm,
      actualConsumption: actualConsumption ?? this.actualConsumption,
      fuelUsed: fuelUsed ?? this.fuelUsed,
      fuelCost: fuelCost ?? this.fuelCost,
      trafficLevel: trafficLevel ?? this.trafficLevel,
      elevationGain: elevationGain ?? this.elevationGain,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Trip süresini hesaplar
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Ortalama hızı hesaplar (km/saat)
  double? get averageSpeed {
    final dur = duration;
    if (dur == null || dur.inSeconds == 0) return null;
    return distanceKm / (dur.inHours);
  }

  /// Gerçek tüketimi hesaplar (eğer fuelUsed varsa)
  double? get calculatedConsumption {
    if (fuelUsed == null || fuelUsed == 0) return null;
    return (fuelUsed! / distanceKm) * 100;
  }
}
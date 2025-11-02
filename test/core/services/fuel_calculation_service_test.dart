import 'package:flutter_test/flutter_test.dart';
import 'package:rotonomi/core/services/fuel_calculation_service.dart';

void main() {
  late FuelCalculationService service;

  setUp(() {
    service = FuelCalculationService();
  });

  group('FuelCalculationService Tests', () {
    test('should calculate fuel cost for sedan vehicle', () {
      // Örnek: 100 km, benzin fiyatı 30 TL/L
      final result = service.calculateFuelCost(
        distanceKm: 100,
        fuelType: 'Benzin',
        vehicleClass: 'Sedan',
        fuelPrice: 30.0,
      );

      expect(result.fuelConsumed, greaterThan(0));
      expect(result.totalCost, greaterThan(0));
      expect(result.costPerKm, greaterThan(0));
    });

    test('should calculate diesel cost correctly', () {
      final result = service.calculateFuelCost(
        distanceKm: 100,
        fuelType: 'Dizel',
        vehicleClass: 'SUV',
        fuelPrice: 35.0,
      );

      expect(result.fuelConsumed, greaterThan(0));
      expect(result.totalCost, greaterThan(0));
    });

    test('should return zero cost for zero distance', () {
      final result = service.calculateFuelCost(
        distanceKm: 0,
        fuelType: 'Benzin',
        vehicleClass: 'Sedan',
        fuelPrice: 30.0,
      );

      expect(result.fuelConsumed, equals(0));
      expect(result.totalCost, equals(0));
    });
  });
}

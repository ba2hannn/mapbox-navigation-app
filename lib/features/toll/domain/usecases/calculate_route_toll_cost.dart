// Path: lib/features/toll/domain/usecases/calculate_route_toll_cost.dart

import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../../core/services/directions_service.dart' as directions;
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/toll_gate_entity.dart';
import '../repositories/toll_repository.dart';

class CalculateRouteTollCost implements UseCase<double, RouteTollParams> {
  final TollRepository repository;

  CalculateRouteTollCost(this.repository);

  @override
  Future<Either<Failure, double>> call(RouteTollParams params) async {
    final allGatesResult = await repository.getAllTollGates();

    return allGatesResult.fold(
      (failure) => Left(failure),
      (allGates) async {
        if (allGates.isEmpty) {
          return const Right(0.0);
        }

        // YENİ ALGORİTMA: Rota adımlarını ve kavşakları analiz et
        final List<TollGateEntity> detectedGates = [];
        
        for (final leg in params.route.legs) {
          for (final step in leg.steps) {
            for (final intersection in step.intersections) {
              // Eğer bu intersection bir gişe içeriyorsa...
              if (intersection.tollCollection != null) {
                final tollLocationFromMapbox = intersection.location;

                // Mapbox'ın verdiği koordinata en yakın gişeyi kendi veritabanımızda bulalım.
                final matchedGate = _findNearestGateByCoord(tollLocationFromMapbox, allGates);

                if (matchedGate != null) {
                  // Eğer daha önce eklemediysek, listeye ekle.
                  if (!detectedGates.any((g) => g.id == matchedGate.id)) {
                    detectedGates.add(matchedGate);
                  }
                }
              }
            }
          }
        }

        if (detectedGates.length < 2) {
          return const Right(0.0);
        }

        // Ücretleri hesapla...
        double totalCost = 0.0;
        for (int i = 0; i < detectedGates.length - 1; i++) {
          final entryGate = detectedGates[i];
          final exitGate = detectedGates[i + 1];

          final costResult = await repository.getTollCost(
            entryGateId: entryGate.id,
            exitGateId: exitGate.id,
          );
          
          costResult.fold(
            (failure) => null,
            (costEntity) {
              final segmentCost = costEntity.getCostForClass(params.vehicleClass);
              totalCost += segmentCost;
            }
          );
        }
        
        return Right(totalCost);
      },
    );
  }

  // YENİ YARDIMCI METOD: Mapbox koordinatına en yakın gişeyi bulur.
  TollGateEntity? _findNearestGateByCoord(List<double> mapboxCoord, List<TollGateEntity> allGates) {
    TollGateEntity? nearestGate;
    double minDistance = double.infinity;

    final mapboxLng = mapboxCoord[0];
    final mapboxLat = mapboxCoord[1];

    for (final gate in allGates) {
      final distance = geo.Geolocator.distanceBetween(
        mapboxLat,
        mapboxLng,
        gate.latitude,
        gate.longitude,
      );

      // Arama yarıçapını makul bir seviyede tutalım (örneğin 1 km)
      if (distance < minDistance && distance < 1000) {
        minDistance = distance;
        nearestGate = gate;
      }
    }
    
    return nearestGate;
  }
}

// Parametre sınıfı
class RouteTollParams {
  final directions.Route route;
  final int vehicleClass; // Araç sınıfı (1-5)
  RouteTollParams({required this.route, required this.vehicleClass});
}
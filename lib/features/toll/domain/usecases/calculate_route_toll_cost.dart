// Path: lib/features/toll/domain/usecases/calculate_route_toll_cost.dart

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
        
        debugPrint('🔍 Gişe arama başlatıldı. Toplam ${allGates.length} gişe veritabanında mevcut.');
        
        for (final leg in params.route.legs) {
          for (final step in leg.steps) {
            for (final intersection in step.intersections) {
              // Eğer bu intersection bir gişe içeriyorsa...
              if (intersection.tollCollection != null) {
                final tollLocationFromMapbox = intersection.location;
                final tollName = intersection.tollCollection!.name;

                debugPrint('📍 Mapbox gişe tespit edildi: "$tollName" konum: [${tollLocationFromMapbox[1]}, ${tollLocationFromMapbox[0]}]');

                // Mapbox'ın verdiği koordinata en yakın gişeyi kendi veritabanımızda bulalım.
                final matchedGate = _findNearestGateByCoord(tollLocationFromMapbox, allGates);

                if (matchedGate != null) {
                  debugPrint('✅ Eşleşen gişe bulundu: "${matchedGate.name}" (ID: ${matchedGate.id})');
                  // Eğer daha önce eklemediysek, listeye ekle.
                  if (!detectedGates.any((g) => g.id == matchedGate.id)) {
                    detectedGates.add(matchedGate);
                    debugPrint('➕ Gişe listeye eklendi: ${matchedGate.name}');
                  } else {
                    debugPrint('⏭️ Gişe zaten listede var: ${matchedGate.name}');
                  }
                } else {
                  debugPrint('❌ Bu Mapbox gişesine uygun veritabanı gişesi bulunamadı: "$tollName"');
                }
              }
            }
          }
        }

        debugPrint('📊 Toplam tespit edilen benzersiz gişe sayısı: ${detectedGates.length}');
        for (int i = 0; i < detectedGates.length; i++) {
          debugPrint('   ${i + 1}. ${detectedGates[i].name} (ID: ${detectedGates[i].id})');
        }

        if (detectedGates.length < 2) {
          debugPrint('⚠️ Yeterli gişe bulunamadı (${detectedGates.length}), ücret 0 olarak hesaplandı.');
          return const Right(0.0);
        }

        // Ücretleri hesapla...
        double totalCost = 0.0;
        debugPrint('💰 Gişe ücretleri hesaplanıyor...');
        
        for (int i = 0; i < detectedGates.length - 1; i++) {
          final entryGate = detectedGates[i];
          final exitGate = detectedGates[i + 1];

          debugPrint('   🔄 ${entryGate.name} → ${exitGate.name} arası ücret hesaplanıyor...');

          final costResult = await repository.getTollCost(
            entryGateId: entryGate.id,
            exitGateId: exitGate.id,
          );
          
          costResult.fold(
            (failure) {
              debugPrint('   ❌ Ücret hesaplanamadı: $failure');
            },
            (costEntity) {
              final segmentCost = costEntity.getCostForClass(params.vehicleClass);
              debugPrint('   ✅ ${entryGate.name} → ${exitGate.name}: ₺${segmentCost.toStringAsFixed(2)}');
              totalCost += segmentCost;
            }
          );
        }
        
        debugPrint('💵 Toplam hesaplanan gişe ücreti: ₺${totalCost.toStringAsFixed(2)}');
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
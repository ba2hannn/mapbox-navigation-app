// Path: lib/core/usecases/usecase.dart

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

// Result: Başarılı durumda dönecek olan veri tipi (örn: double, List<User>)
// Params: UseCase'in ihtiyaç duyduğu parametreler (örn: String userId, RouteTollParams)
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

// Eğer bir UseCase parametreye ihtiyaç duymuyorsa bunu kullanabiliriz.
class NoParams {}
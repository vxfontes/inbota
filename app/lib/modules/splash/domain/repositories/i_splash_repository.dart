import 'package:dartz/dartz.dart';
import 'package:inbota/modules/splash/data/models/health_status_output.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class ISplashRepository {
  Future<Either<Failure, HealthStatusOutput>> checkHealth();
}

import 'package:inbota/modules/splash/data/models/health_status_output.dart';
import 'package:inbota/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class CheckHealthUsecase extends IBUsecase {
  final ISplashRepository _repository;

  CheckHealthUsecase(this._repository);

  UsecaseResponse<Failure, HealthStatusOutput> call() {
    return _repository.checkHealth();
  }
}

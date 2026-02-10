import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class LogoutUsecase extends IBUsecase {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  UsecaseResponse<Failure, void> call() {
    return _repository.logout();
  }
}

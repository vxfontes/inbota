import 'package:inbota/modules/auth/data/models/auth_login_input.dart';
import 'package:inbota/modules/auth/data/models/auth_session_output.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class LoginUsecase extends IBUsecase {
  final IAuthRepository _repository;

  LoginUsecase(this._repository);

  UsecaseResponse<Failure, AuthSessionOutput> call(AuthLoginInput input) {
    return _repository.login(input);
  }
}

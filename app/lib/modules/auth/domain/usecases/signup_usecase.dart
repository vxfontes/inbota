import 'package:inbota/modules/auth/data/models/auth_session_output.dart';
import 'package:inbota/modules/auth/data/models/auth_signup_input.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class SignupUsecase extends IBUsecase {
  final IAuthRepository _repository;

  SignupUsecase(this._repository);

  UsecaseResponse<Failure, AuthSessionOutput> call(AuthSignupInput input) {
    return _repository.signup(input);
  }
}

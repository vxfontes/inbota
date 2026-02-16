import 'package:inbota/modules/auth/data/models/auth_user_model.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetMeUsecase extends IBUsecase {
  final IAuthRepository _repository;

  GetMeUsecase(this._repository);

  UsecaseResponse<Failure, AuthUserModel> call() {
    return _repository.me();
  }
}

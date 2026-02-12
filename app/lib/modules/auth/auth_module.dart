import 'package:inbota/modules/auth/data/repositories/auth_repository.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/modules/auth/domain/usecases/login_usecase.dart';
import 'package:inbota/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:inbota/modules/auth/domain/usecases/signup_usecase.dart';

class AuthModule {
  static void binds(i) {
    // repository
    i.addLazySingleton<IAuthRepository>(AuthRepository.new);

    // usecases
    i.addLazySingleton<LoginUsecase>(LoginUsecase.new);
    i.addLazySingleton<SignupUsecase>(SignupUsecase.new);
    i.addLazySingleton<LogoutUsecase>(LogoutUsecase.new);
  }
}

import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/auth/data/repositories/auth_repository.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/modules/auth/domain/usecases/login_usecase.dart';
import 'package:inbota/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:inbota/modules/auth/domain/usecases/signup_usecase.dart';
import 'package:inbota/shared/services/http/http_client.dart';
import 'package:inbota/shared/storage/auth_token_store.dart';

class AuthModule {
  static void binds(i) {
    i.addLazySingleton<IAuthRepository>(
      () => AuthRepository(
        i.get<IHttpClient>(),
        i.get<AuthTokenStore>(),
      ),
    );

    i.addLazySingleton<LoginUsecase>(LoginUsecase.new);
    i.addLazySingleton<SignupUsecase>(SignupUsecase.new);
    i.addLazySingleton<LogoutUsecase>(LogoutUsecase.new);
  }
}

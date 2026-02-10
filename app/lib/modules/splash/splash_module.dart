import 'package:inbota/modules/splash/data/repositories/splash_repository.dart';
import 'package:inbota/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:inbota/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class SplashModule {
  static void binds(i) {
    i.addLazySingleton<ISplashRepository>(
      () => SplashRepository(i.get<IHttpClient>()),
    );
    i.addLazySingleton<CheckHealthUsecase>(CheckHealthUsecase.new);
  }
}

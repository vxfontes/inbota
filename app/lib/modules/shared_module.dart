import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/auth/auth_module.dart';
import 'package:inbota/modules/inbox/inbox_module.dart';
import 'package:inbota/modules/reminders/reminders_module.dart';
import 'package:inbota/modules/splash/splash_module.dart';
import 'package:inbota/modules/tasks/tasks_module.dart';
import 'package:inbota/shared/services/http/dio_http_client.dart';
import 'package:inbota/shared/services/http/http_client.dart';
import 'package:inbota/shared/storage/auth_token_store.dart';
import 'package:inbota/shared/storage/token_storage.dart';

class SharedModule extends Module {
  @override
  void exportedBinds(i) {
    i.addLazySingleton<TokenStorage>(TokenStorage.new);
    i.addLazySingleton<AuthTokenStore>(() => AuthTokenStore(i.get<TokenStorage>()));
    i.addLazySingleton<IHttpClient>(
      () => DioHttpClient(Profile.DEV, tokenStore: i.get<AuthTokenStore>()),
    );

    // modules
    AuthModule.binds(i);
    InboxModule.binds(i);
    RemindersModule.binds(i);
    SplashModule.binds(i);
    TasksModule.binds(i);
  }
}

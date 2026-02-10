import 'package:flutter_modular/flutter_modular.dart';

import '../screens/home_module/home_module.dart';
import '../screens/splash_module/splash_module.dart';
import 'app_routes.dart';

class AppModule extends Module {
  @override
  void routes(RouteManager r) {
    r.module(AppRoutes.splash, module: SplashModule());
    r.module(AppRoutes.home, module: HomeModule());
  }
}

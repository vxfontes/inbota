import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/splash_module/pages/splash_page.dart';

class SplashModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SplashPage());
  }
}

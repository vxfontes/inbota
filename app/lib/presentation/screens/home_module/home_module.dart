import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/pages/home_page.dart';


class HomeModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const HomePage());
  }
}

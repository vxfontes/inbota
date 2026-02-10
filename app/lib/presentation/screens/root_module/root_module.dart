import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/root_module/pages/root_page.dart';

class RootModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const RootPage());
  }
}

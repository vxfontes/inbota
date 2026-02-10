import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_controller.dart';

import 'pages/settings_page.dart';

class SettingsModule extends Module {

  // core_modules
  @override
  List<Module> get imports => [SharedModule()];


  @override
  void binds(Injector i) {
    i.addSingleton<SettingsController>(SettingsController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const SettingsPage());
  }
}

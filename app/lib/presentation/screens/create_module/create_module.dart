import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/create_module/controller/create_controller.dart';
import 'package:inbota/presentation/screens/create_module/pages/create_page.dart';

class CreateModule extends Module {
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void binds(Injector i) {
    i.addSingleton<CreateController>(CreateController.new);
  }

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const CreatePage(),
      transition: TransitionType.noTransition,
      duration: Duration.zero,
    );
  }
}

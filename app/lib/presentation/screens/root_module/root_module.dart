import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/shared_module.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/home_module/home_module.dart';
import 'package:inbota/presentation/screens/reminders_module/reminders_module.dart';
import 'package:inbota/presentation/screens/root_module/pages/root_page.dart';
import 'package:inbota/presentation/screens/root_module/pages/root_placeholder_page.dart';

class RootModule extends Module {
  // core_modules
  @override
  List<Module> get imports => [SharedModule()];

  @override
  void routes(RouteManager r) {
    r.child(
      AppRoutes.splash,
      child: (_) => const RootPage(),
      children: [
        // modulos internos do app
        ModuleRoute(
          AppRoutes.home,
          module: HomeModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ModuleRoute(
          AppRoutes.reminders,
          module: RemindersModule(),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        // mock rotas ainda sem implementação
        ChildRoute(
          AppRoutes.create,
          child: (_) => const RootPlaceholderPage(title: 'Criar'),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ChildRoute(
          AppRoutes.shopping,
          child: (_) => const RootPlaceholderPage(title: 'Compras'),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
        ChildRoute(
          AppRoutes.events,
          child: (_) => const RootPlaceholderPage(title: 'Eventos'),
          transition: TransitionType.noTransition,
          duration: Duration.zero,
        ),
      ],
    );
  }
}

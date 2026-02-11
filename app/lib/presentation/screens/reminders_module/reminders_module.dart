import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/presentation/routes/app_routes.dart';
import 'package:inbota/presentation/screens/reminders_module/pages/reminders_page.dart';

class RemindersModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const RemindersPage());
  }
}

import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/presentation/routes/app_routes.dart';

import 'pages/login_page.dart';
import 'pages/pre_login_page.dart';
import 'pages/signup_page.dart';

class AuthModule extends Module {
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';

  @override
  void routes(RouteManager r) {
    r.child(AppRoutes.splash, child: (_) => const PreLoginPage());
    r.child(routeLogin, child: (_) => const LoginPage());
    r.child(routeSignup, child: (_) => const SignupPage());
  }
}

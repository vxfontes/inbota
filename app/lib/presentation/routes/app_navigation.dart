import 'package:flutter_modular/flutter_modular.dart';

class AppNavigation {
  AppNavigation._();

  static Future<T?> push<T extends Object?>(String route, {dynamic args}) {
    return Modular.to.pushNamed<T>(route, arguments: args);
  }

  static void navigate(String route, {dynamic args}) {
    Modular.to.navigate(route, arguments: args);
  }

  static Future<T?> replace<T extends Object?>(String route, {dynamic args}) {
    return Modular.to.pushReplacementNamed(route, arguments: args);
  }

  static void pop<T extends Object?>([T? result]) {
    Modular.to.pop(result);
  }

  static Future<T?> clearAndPush<T extends Object?>(String route, {dynamic args}) {
    return Modular.to.pushNamedAndRemoveUntil<T>(route, (r) => false, arguments: args);
  }
}

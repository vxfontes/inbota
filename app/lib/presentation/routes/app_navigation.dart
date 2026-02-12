import 'dart:ui';

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
    if (Modular.to.canPop()) {
      Modular.to.pop(result);
    }
  }

  static bool canPop() {
    return Modular.to.canPop();
  }

  static void addListener(VoidCallback listener) {
    Modular.to.addListener(listener);
  }

  static void removeListener(VoidCallback listener) {
    Modular.to.removeListener(listener);
  }

  static String get path => Modular.to.path;

  static Future<T?> clearAndPush<T extends Object?>(String route, {dynamic args}) {
    return Modular.to.pushNamedAndRemoveUntil<T>(route, (r) => false, arguments: args);
  }
}

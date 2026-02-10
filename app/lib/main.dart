import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'presentation/app.dart';
import 'presentation/routes/app_module.dart';

void main() {
  runApp(ModularApp(module: AppModule(), child: const AppWidget()));
}

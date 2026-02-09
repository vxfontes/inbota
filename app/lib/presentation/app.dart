import 'package:flutter/material.dart';

import '../shared/theme/app_theme.dart';
import 'screens/splash_screen.dart';

class InbotaApp extends StatelessWidget {
  const InbotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inbota',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}

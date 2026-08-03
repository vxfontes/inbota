import 'package:flutter/material.dart';
import 'package:organiq/shared/storage/app_preferences.dart';

class ThemeController {
  static const _key = 'theme_mode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(_load());

  static ThemeMode _load() {
    final saved = AppPreferences.instance.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    AppPreferences.instance.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  void dispose() => themeMode.dispose();
}

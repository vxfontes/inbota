import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary700,
      onPrimary: Colors.white,
      secondary: AppColors.ai600,
      onSecondary: Colors.white,
      error: AppColors.danger600,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      background: AppColors.background,
      onBackground: AppColors.text,
    );

    final baseText = GoogleFonts.manropeTextTheme().apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseText.copyWith(
        titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardTheme(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary200,
        selectedColor: AppColors.primary600,
        labelStyle: const TextStyle(color: AppColors.text),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary700,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}

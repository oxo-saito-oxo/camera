import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFEAE2D6);
  static const surface = Color(0xFFD5C3AA);
  static const secondary = Color(0xFF867666);
  static const accent = Color(0xFFE1B80D);
}

final appTheme = ThemeData(
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.secondary,
    error: Colors.redAccent,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.secondary,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
    ),
  ),
  useMaterial3: true,
);

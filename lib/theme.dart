import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF12001C);
  static const surface = Color(0xFF1E0630);
  static const surfaceHigh = Color(0xFF2B0B42);
  static const tile = Color(0xFF5A3E5E);
  static const chip = Color(0xFF4A2477);
  static const accent = Color(0xFFDE7A52);
  static const text = Color(0xFFF5EAFB);
  static const muted = Color(0xFF8E6BA8);
}

/// Text/icon colour used on top of the orange accent.
const kOnAccent = Color(0xFF3A1200);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: kOnAccent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      secondary: AppColors.chip,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.text,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: kOnAccent,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

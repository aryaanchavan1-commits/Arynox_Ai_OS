import 'package:flutter/material.dart';
import 'app_colors.dart';

class ArynoxTheme {
  ArynoxTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: ArynoxColors.primary,
        secondary: ArynoxColors.accent,
        surface: ArynoxColors.surfaceLight,
        error: ArynoxColors.error,
      ),
      scaffoldBackgroundColor: ArynoxColors.backgroundLight,
      fontFamily: 'ArynoxSans',
      cardTheme: CardTheme(
        color: ArynoxColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArynoxColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArynoxColors.primary, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A000000),
        thickness: 1,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: ArynoxColors.primaryLight,
        secondary: ArynoxColors.accent,
        surface: ArynoxColors.surfaceDark,
        error: ArynoxColors.error,
      ),
      scaffoldBackgroundColor: ArynoxColors.backgroundDark,
      fontFamily: 'ArynoxSans',
      cardTheme: CardTheme(
        color: ArynoxColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ArynoxColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ArynoxColors.primaryLight, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF),
        thickness: 1,
      ),
    );
  }
}

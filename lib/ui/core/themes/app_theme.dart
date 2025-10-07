import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const primaryColor = Color(0xFF6B705C);
    const secondaryColor = Color(0xFFCB997E);
    const backgroundColor = Color(0xFFB7B7A4);
    const cardBackgroundColor = Color(0xFFFFE8D6);

    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        background: backgroundColor,
        onSurfaceVariant: Color(0xFF3B3535),
        surface: Colors.white,
        surfaceContainerHighest: Color(0xFFFFE8D6),
        onSurface: Colors.black,
        error: Colors.red,
        onError: Colors.white,

      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDDBEA9), brightness: Brightness.dark),
      useMaterial3: true,
    );
  }
}


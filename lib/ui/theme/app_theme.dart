import 'package:flutter/material.dart';

class AppTheme {
  static const String defaultFontFamily = 'Google Sans';

  static ThemeData light(ColorScheme? dynamicColorScheme, {String fontFamily = defaultFontFamily}) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData dark(ColorScheme? dynamicColorScheme, {String fontFamily = defaultFontFamily, bool isAmoled = false}) {
    final baseScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        );

    final scheme = isAmoled
        ? baseScheme.copyWith(surface: Colors.black, surfaceContainer: const Color(0xFF121212))
        : baseScheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: isAmoled ? Colors.black : scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: isAmoled ? Colors.black : scheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

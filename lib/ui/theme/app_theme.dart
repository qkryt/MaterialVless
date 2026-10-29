import 'package:flutter/material.dart';

class AppTheme {
  static const String defaultFontFamily = 'Google Sans';

  static const List<String> builtInFonts = [
    'Google Sans',
    'Roboto',
    'Segoe UI',
    'Consolas',
    'Arial',
    'Tahoma',
  ];

  static const List<int> paletteSeeds = [
    0xFF6750A4, // Deep Purple (Default Material You)
    0xFF1E88E5, // Electric Blue
    0xFF00897B, // Emerald Teal
    0xFF2E7D32, // Forest Green
    0xFFF57C00, // Sunset Orange
    0xFFD32F2F, // Ruby Crimson
    0xFFE91E63, // Cyber Pink
    0xFF546E7A, // Graphite Slate
  ];

  static ThemeData light(
    ColorScheme? dynamicColorScheme, {
    String fontFamily = defaultFontFamily,
    int accentColor = 0xFF6750A4,
  }) {
    final scheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: Color(accentColor),
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  static ThemeData dark(
    ColorScheme? dynamicColorScheme, {
    String fontFamily = defaultFontFamily,
    bool isAmoled = false,
    int accentColor = 0xFF6750A4,
  }) {
    final baseScheme = dynamicColorScheme ??
        ColorScheme.fromSeed(
          seedColor: Color(accentColor),
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
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

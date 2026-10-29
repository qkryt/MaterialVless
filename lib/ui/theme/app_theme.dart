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
    bool hasBackgroundImage = false,
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
      scaffoldBackgroundColor: hasBackgroundImage ? Colors.transparent : scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: hasBackgroundImage ? scheme.surfaceContainer.withOpacity(0.88) : scheme.surfaceContainer,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: hasBackgroundImage ? Colors.transparent : scheme.surface,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        minThumbLength: 48,
        thickness: const WidgetStatePropertyAll(7),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return scheme.primary;
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withOpacity(0.8);
          }
          return scheme.onSurfaceVariant.withOpacity(0.35);
        }),
      ),
    );
  }

  static ThemeData dark(
    ColorScheme? dynamicColorScheme, {
    String fontFamily = defaultFontFamily,
    bool isAmoled = false,
    int accentColor = 0xFF6750A4,
    bool hasBackgroundImage = false,
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
      scaffoldBackgroundColor: hasBackgroundImage ? Colors.transparent : (isAmoled ? Colors.black : scheme.surface),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: hasBackgroundImage
            ? (isAmoled ? const Color(0xFF121212).withOpacity(0.85) : scheme.surfaceContainer.withOpacity(0.85))
            : (isAmoled ? const Color(0xFF121212) : scheme.surfaceContainer),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: hasBackgroundImage ? Colors.transparent : (isAmoled ? Colors.black : scheme.surface),
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        minThumbLength: 48,
        thickness: const WidgetStatePropertyAll(7),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return scheme.primary;
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withOpacity(0.8);
          }
          return scheme.onSurfaceVariant.withOpacity(0.35);
        }),
      ),
    );
  }
}

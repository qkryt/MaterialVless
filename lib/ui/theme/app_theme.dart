import 'package:flutter/material.dart';

class AppTheme {
  static const String defaultFontFamily = 'Google Sans';

  /// Светлая тема в стиле Qt6 Fusion Desktop
  static ThemeData light(ColorScheme? dynamicColorScheme, {String fontFamily = defaultFontFamily}) {
    const primary = Color(0xFF1E6DEB);
    const surface = Color(0xFFF2F4F8);
    const cardBg = Color(0xFFFFFFFF);
    const cardHover = Color(0xFFF8F9FA);
    const border = Color(0xFFD0D5DD);
    const onSurface = Color(0xFF1F2937);
    const onSurfaceVariant = Color(0xFF4B5563);

    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDBEAFE),
      onPrimaryContainer: const Color(0xFF1E40AF),
      secondary: const Color(0xFF3B82F6),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEFF6FF),
      onSecondaryContainer: const Color(0xFF1E3A8A),
      tertiary: const Color(0xFF0284C7),
      onTertiary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: cardBg,
      surfaceContainerHigh: cardHover,
      surfaceContainerHighest: const Color(0xFFE5E7EB),
      onSurfaceVariant: onSurfaceVariant,
      outline: border,
      outlineVariant: const Color(0xFFE5E7EB),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
    );

    return _buildTheme(scheme, fontFamily);
  }

  /// Тёмная тема в стиле Qt6 Fusion Desktop (графитовый фон, 1px рамки, фирменный синий Qt6)
  static ThemeData dark(ColorScheme? dynamicColorScheme, {String fontFamily = defaultFontFamily, bool isAmoled = false}) {
    const primary = Color(0xFF3574F0);
    final surface = isAmoled ? Colors.black : const Color(0xFF1B1D22);
    final cardBg = isAmoled ? const Color(0xFF0F1014) : const Color(0xFF24272F);
    final cardHover = isAmoled ? const Color(0xFF171920) : const Color(0xFF2D313B);
    final border = isAmoled ? const Color(0xFF262A34) : const Color(0xFF383D4A);
    const onSurface = Color(0xFFEDEDED);
    const onSurfaceVariant = Color(0xFF9AA0A6);

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFDBEAFE),
      secondary: const Color(0xFF60A5FA),
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF1E293B),
      onSecondaryContainer: const Color(0xFF93C5FD),
      tertiary: const Color(0xFF38BDF8),
      onTertiary: Colors.black,
      surface: surface,
      onSurface: onSurface,
      surfaceContainer: cardBg,
      surfaceContainerHigh: cardHover,
      surfaceContainerHighest: const Color(0xFF363B48),
      onSurfaceVariant: onSurfaceVariant,
      outline: border,
      outlineVariant: const Color(0xFF2A2E38),
      error: const Color(0xFFEF4444),
      onError: Colors.white,
    );

    return _buildTheme(scheme, fontFamily);
  }

  static ThemeData _buildTheme(ColorScheme scheme, String fontFamily) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: scheme.outline, width: 1.0),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline, width: 1.0),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.outline, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.outline, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(color: scheme.outline, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}

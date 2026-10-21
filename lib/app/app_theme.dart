import 'package:flutter/material.dart';

/// The four themes. Light is the default - never dark.
enum AppThemeKind { light, sepia, softBlue, dark }

class AppTheme {
  static const _emerald = Color(0xFF1F7A5C);
  static const _gold = Color(0xFFC9A24B);

  static ThemeData of(AppThemeKind kind, {String font = 'Inter'}) {
    return _withFont(_pick(kind), font);
  }

  // Urdu UI text uses the Nastaliq font; everything else uses Inter.
  static ThemeData _withFont(ThemeData t, String font) =>
      font == 'Inter' ? t : t.copyWith(textTheme: t.textTheme.apply(fontFamily: font));

  static ThemeData _pick(AppThemeKind kind) {
    switch (kind) {
      case AppThemeKind.light:
        return _build(const ColorScheme.light(
          primary: _emerald, onPrimary: Colors.white,
          secondary: _gold, onSecondary: Color(0xFF2B2B2B),
          surface: Colors.white, onSurface: Color(0xFF2A3A36),
        ), const Color(0xFFFBF8F1));
      case AppThemeKind.sepia:
        return _build(const ColorScheme.light(
          primary: Color(0xFF7A5230), onPrimary: Colors.white,
          secondary: Color(0xFFB8893B), onSecondary: Color(0xFF2B2B2B),
          surface: Color(0xFFFFF8E8), onSurface: Color(0xFF3F3125),
        ), const Color(0xFFF4ECD8));
      case AppThemeKind.softBlue:
        return _build(const ColorScheme.light(
          primary: Color(0xFF2B6CA3), onPrimary: Colors.white,
          secondary: Color(0xFF4FA3B8), onSecondary: Colors.white,
          surface: Colors.white, onSurface: Color(0xFF243642),
        ), const Color(0xFFEAF4FB));
      case AppThemeKind.dark:
        // Deep blue-green slate, not black. Only used if chosen in Settings.
        return _build(const ColorScheme.dark(
          primary: Color(0xFF5CC4A0), onPrimary: Color(0xFF0F2A25),
          secondary: Color(0xFFE0BC6A), onSecondary: Color(0xFF2B2B2B),
          surface: Color(0xFF28454A), onSurface: Color(0xFFE6F0EE),
        ), const Color(0xFF1F3A3F));
    }
  }

  static ThemeData _build(ColorScheme scheme, Color background) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: background, foregroundColor: scheme.onSurface,
        elevation: 0, centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface, elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}

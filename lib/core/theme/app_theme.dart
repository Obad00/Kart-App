import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Soft white used for text/icons to avoid pure white fatigue
  static const Color _softWhite = Color(0xFFF6F6F8);
  // Deep but comfortable black (not aggressive)
  static const Color _softBlack = Color(0xFF0A0A0B);
  static const Color _surface = Color(0xFF0D0D0E);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFF0A0A0A),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0A0A0A),
        secondary: Color(0xFF0A0A0A),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSurface: Color(0xFF0A0A0A),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A0A0A)),
        bodyMedium: const TextStyle(fontSize: 16, color: Color(0xFF0A0A0A)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0A0A0A)),
        ),
        labelStyle: const TextStyle(color: Color(0xFF0A0A0A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _softBlack,
      primaryColor: _softWhite,
      colorScheme: ColorScheme.dark(
        primary: _softWhite,
        secondary: _softWhite,
        surface: _surface,
        onPrimary: _softBlack,
        onSurface: _softWhite,
      ),
      textTheme:
          base.textTheme.apply(bodyColor: _softWhite, displayColor: _softWhite),
      cardTheme: const CardThemeData(
        color: _surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      dividerColor: Colors.white12,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
    );
  }
}

import 'package:flutter/material.dart';
import 'card_theme.dart';

class CardThemeOption {
  final String key;
  final String label;
  final DigitalCardTheme theme;
  final bool isProOnly;

  const CardThemeOption({
    required this.key,
    required this.label,
    required this.theme,
    this.isProOnly = false,
  });
}

class CardThemes {
  /// 🖤 CLASSIQUE (par défaut)
  static const defaultTheme = DigitalCardTheme(
    background: Color(0xFF0B0C0E),
    foreground: Color(0xFFF2F3F5),
    border: Color(0xFF1E2024),
    subtle: Color(0xFF9A9CA3),
    borderRadius: 22,
    elevation: 0.14,
  );

  /// 🌤 CLEAN LIGHT (PRO)
  static const cleanLight = DigitalCardTheme(
    background: Color(0xFFF9FAFB),
    foreground: Color(0xFF0F172A),
    border: Color(0xFFE5E7EB),
    subtle: Color(0xFF64748B),
    borderRadius: 28,
    elevation: 0.08,
  );

  /// 🌑 DARK MINIMAL (PRO)
  static const darkMinimal = DigitalCardTheme(
    background: Color(0xFF0E1117), // noir bleuté premium
    foreground: Color(0xFFE6EDF3),
    border: Color(0xFF21262D),
    subtle: Color(0xFF8B949E),
    borderRadius: 18,
    elevation: 0.22,
    glow: true,
  );

  /// 🔥 SOURCE UNIQUE DES THÈMES
  static const List<CardThemeOption> options = [
    CardThemeOption(
      key: 'default',
      label: 'Par défaut',
      theme: defaultTheme,
    ),
    CardThemeOption(
      key: 'clean_light',
      label: 'Clean Light',
      theme: cleanLight,
      isProOnly: true,
    ),
    CardThemeOption(
      key: 'dark_minimal',
      label: 'Dark Minimal',
      theme: darkMinimal,
      isProOnly: true,
    ),
  ];
}

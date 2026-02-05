import 'package:flutter/material.dart';
import 'card_theme.dart';

class CardThemes {
  static const defaultTheme = DigitalCardTheme(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0A0A0A),
    border: Color(0xFFE6E6E9),
    subtle: Color(0xFF8E8E93),
  );

  static const darkMinimal = DigitalCardTheme(
    background: Color(0xFF0A0A0B),
    foreground: Color(0xFFF6F6F8),
    border: Color(0xFF1C1C1E),
    subtle: Color(0xFF8E8E93),
  );

  static const cleanLight = DigitalCardTheme(
    background: Color(0xFFF7F7F9),
    foreground: Color(0xFF111111),
    border: Color(0xFFDDDEE3),
    subtle: Color(0xFF7A7A80),
  );
}

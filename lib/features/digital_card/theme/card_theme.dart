import 'package:flutter/material.dart';

class DigitalCardTheme {
  final Color background;
  final Color foreground;
  final Color border;
  final Color subtle;

  // Design tuning
  final double borderRadius;
  final double elevation;
  final bool glow;

  const DigitalCardTheme({
    required this.background,
    required this.foreground,
    required this.border,
    required this.subtle,
    this.borderRadius = 22,
    this.elevation = 0.12,
    this.glow = false,
  });
}

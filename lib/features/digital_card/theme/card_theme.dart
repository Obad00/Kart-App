import 'package:flutter/material.dart';

class DigitalCardTheme {
  final Color background;
  final Color foreground;
  final Color border;
  final Color subtle;
  final double borderRadius;

  const DigitalCardTheme({
    required this.background,
    required this.foreground,
    required this.border,
    required this.subtle,
    this.borderRadius = 28,
  });
}

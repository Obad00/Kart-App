import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Texture "métal brossé" très discrète de la carte noire : fines stries
/// horizontales d'opacité variable, sans reflet ni animation. Tirage
/// pseudo-aléatoire à graine fixe : le motif est identique d'un rendu à
/// l'autre (pas de scintillement, export stable).
class BrushedTexture extends StatelessWidget {
  /// Couleur des stries claires (celle du texte sur la carte).
  final Color lightStroke;

  /// Couleur des stries sombres (le fond de la carte).
  final Color darkStroke;

  const BrushedTexture({
    super.key,
    required this.lightStroke,
    required this.darkStroke,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BrushedPainter(lightStroke, darkStroke),
        size: Size.infinite,
      ),
    );
  }
}

class _BrushedPainter extends CustomPainter {
  final Color lightStroke;
  final Color darkStroke;

  _BrushedPainter(this.lightStroke, this.darkStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()
      ..strokeWidth = 0.6
      ..isAntiAlias = true;

    for (double y = 0; y < size.height; y += 1.4) {
      final light = rng.nextBool();
      final alpha = light
          ? 0.012 + rng.nextDouble() * 0.028
          : 0.10 + rng.nextDouble() * 0.12;
      paint.color = (light ? lightStroke : darkStroke).withValues(alpha: alpha);

      // Stries de longueurs variables plutôt que des lignes pleines : rend
      // l'effet brossé sans motif régulier.
      double x = -rng.nextDouble() * 40;
      while (x < size.width) {
        final len = 30 + rng.nextDouble() * 140;
        canvas.drawLine(Offset(x, y), Offset(x + len, y), paint);
        x += len + rng.nextDouble() * 24;
      }
    }
  }

  @override
  bool shouldRepaint(_BrushedPainter old) =>
      old.lightStroke != lightStroke || old.darkStroke != darkStroke;
}

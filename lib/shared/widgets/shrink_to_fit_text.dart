import 'package:flutter/material.dart';

/// Texte qui tient en [maxLines] lignes sans être coupé tant que c'est
/// possible : s'il déborde à sa taille normale, la police est réduite par
/// petits pas jusqu'à [minFontSize] ; les « … » n'apparaissent qu'en dernier
/// recours, quand même la plus petite taille ne suffit pas.
///
/// Cas réel : « Cabinet Médical Ahmadina Saliou (CMAS) », coupé sur la
/// carte à côté du logo.
class ShrinkToFitText extends StatelessWidget {
  final String text;

  /// Style à la taille normale ; `fontSize` est obligatoire.
  final TextStyle style;
  final int maxLines;
  final double minFontSize;
  final TextAlign textAlign;

  const ShrinkToFitText(
    this.text, {
    super.key,
    required this.style,
    required this.maxLines,
    required this.minFontSize,
    this.textAlign = TextAlign.start,
  });

  static const double _step = 0.5;

  /// Le texte tient-il en [maxLines] lignes dans [maxWidth], à la taille de
  /// [style] ? Mesuré avec le style réellement appliqué par `Text` (police
  /// du thème comprise).
  static bool fits(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required int maxLines,
    required double maxWidth,
    TextAlign textAlign = TextAlign.start,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final ok = !painter.didExceedMaxLines;
    painter.dispose();
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final base = style.fontSize!;

    return LayoutBuilder(
      builder: (context, constraints) {
        bool fits(double size) => ShrinkToFitText.fits(
              context,
              text: text,
              style: style.copyWith(fontSize: size),
              maxLines: maxLines,
              maxWidth: constraints.maxWidth,
              textAlign: textAlign,
            );

        var size = base;
        while (size > minFontSize && !fits(size)) {
          size = (size - _step).clamp(minFontSize, base);
        }

        return Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}

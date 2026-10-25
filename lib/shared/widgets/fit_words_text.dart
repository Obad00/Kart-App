import 'package:flutter/widgets.dart';

/// Nom affiché en grand : jamais coupé au milieu d'un mot. Le texte ne
/// passe à la ligne qu'entre les mots ; si un mot est plus large que la
/// place disponible, la taille descend (par demi-pixel) jusqu'à ce que ce
/// mot tienne, sans passer sous [minFontSize]. Même règle que la page
/// publique (kart-vue-project, `v-fit-text`).
class FitWordsText extends StatelessWidget {
  const FitWordsText(
    this.text, {
    super.key,
    required this.style,
    this.minFontSize = 16,
    this.maxLines,
    this.textAlign,
    this.shrinkToMaxLines = false,
  });

  final String text;

  /// Style à la taille normale (la plus grande).
  final TextStyle style;
  final double minFontSize;
  final int? maxLines;
  final TextAlign? textAlign;

  /// true : la taille baisse aussi jusqu'à ce que tout le texte tienne en
  /// [maxLines] lignes (au lieu d'être coupé par « … »).
  final bool shrinkToMaxLines;

  /// Taille à laquelle le mot le plus large de [text] tient dans [maxWidth].
  static double fittingSize(
    String text,
    TextStyle style,
    double maxWidth, {
    required double minFontSize,
    TextScaler textScaler = TextScaler.noScaling,
    int? maxLines,
  }) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    var size = style.fontSize ?? 14;
    if (words.isEmpty || !maxWidth.isFinite) return size;

    double widest(double fontSize) {
      var max = 0.0;
      for (final word in words) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style.copyWith(fontSize: fontSize)),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        if (painter.width > max) max = painter.width;
        painter.dispose();
      }
      return max;
    }

    // Tout le texte, coupé entre les mots seulement, tient-il en maxLines ?
    bool tooManyLines(double fontSize) {
      if (maxLines == null) return false;
      final painter = TextPainter(
        text: TextSpan(text: text.trim(), style: style.copyWith(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: maxLines,
      )..layout(maxWidth: maxWidth);
      final exceeded = painter.didExceedMaxLines;
      painter.dispose();
      return exceeded;
    }

    while (size > minFontSize && (widest(size) > maxWidth || tooManyLines(size))) {
      size = (size - 0.5).clamp(minFontSize, size);
    }
    return size;
  }

  @override
  Widget build(BuildContext context) {
    // Mesuré avec le style réellement rendu : Text le fusionne avec le
    // style de texte par défaut (espacement des lettres, etc.).
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fittingSize(
          text,
          effective,
          constraints.maxWidth,
          minFontSize: minFontSize,
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: shrinkToMaxLines ? maxLines : null,
        );
        return Text(
          text,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          textAlign: textAlign,
          style: style.copyWith(fontSize: size),
        );
      },
    );
  }
}

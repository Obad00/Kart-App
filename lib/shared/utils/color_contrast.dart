import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Lisibilité d'une couleur d'accent sur la carte publique (contraste WCAG).
///
/// Mêmes règles et mêmes seuils que le backend (App\Support\ColorContrast) :
/// la couleur « Suggérée » vient du serveur ; ce calcul local sert à
/// l'avertissement en direct quand l'utilisateur choisit une couleur à la
/// pipette, dans la palette ou au clavier.
class ColorContrast {
  ColorContrast._();

  /// Fond de la carte publique et du thème sombre.
  static const Color darkBackground = Color(0xFF1A1A1A);

  /// En dessous (seuil WCAG d'une icône ou d'un bouton), la couleur est
  /// signalée « peu lisible ».
  static const double iconRatio = 3.0;

  /// Seuil visé par « Ajuster » (WCAG AA pour du texte).
  static const double textRatio = 4.5;

  /// Rapport de contraste WCAG, de 1 (couleurs identiques) à 21.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static bool isReadableOnCard(Color color) =>
      ratio(color, darkBackground) >= iconRatio;

  /// [color] rendu lisible sur [background] : même teinte, éclaircie (fond
  /// sombre) ou assombrie (fond clair) juste assez pour atteindre
  /// [minimum]. Renvoie [color] tel quel s'il est déjà lisible.
  ///
  /// Sert aux initiales des avatars : écrites dans la couleur d'accent de
  /// la carte, elles devenaient illisibles avec un accent sombre en thème
  /// sombre (bleu marine sur fond presque noir).
  static Color readableOn(
    Color color,
    Color background, {
    double minimum = textRatio,
  }) {
    if (ratio(color, background) >= minimum) return color;

    final hsl = HSLColor.fromColor(color);
    // On s'éloigne du fond : vers le clair s'il est sombre, et inversement.
    final step = background.computeLuminance() < 0.5 ? 0.01 : -0.01;

    var lightness = hsl.lightness;
    while (lightness > 0 && lightness < 1) {
      lightness = (lightness + step).clamp(0.0, 1.0);
      final candidate = hsl.withLightness(lightness).toColor();
      if (ratio(candidate, background) >= minimum) return candidate;
    }
    // Teinte épuisée (blanc ou noir atteint) : le plus contrasté des deux.
    return step > 0 ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  /// Couleur réellement visible quand [overlay] (souvent translucide) est
  /// posé sur [background] — c'est sur elle qu'il faut mesurer le contraste.
  static Color composite(Color overlay, Color background) =>
      Color.alphaBlend(overlay, background);

  /// Même teinte, éclaircie juste assez pour être bien lisible sur la
  /// carte. Renvoie [color] tel quel s'il l'est déjà.
  static Color adjustForCard(Color color) {
    if (ratio(color, darkBackground) >= textRatio) return color;

    final hsl = HSLColor.fromColor(color);
    var lightness = hsl.lightness;
    while (lightness < 1) {
      lightness = math.min(1, lightness + 0.01);
      final candidate = hsl.withLightness(lightness).toColor();
      if (ratio(candidate, darkBackground) >= textRatio) return candidate;
    }
    return hsl.withLightness(1).toColor();
  }
}

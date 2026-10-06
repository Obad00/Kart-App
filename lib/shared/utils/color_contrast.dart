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

import 'package:flutter/widgets.dart';

/// Taille de police du système bornée entre 1.0 et 1.3 pour toute l'app.
/// Sur Android, la taille « Grande » ou plus faisait déborder (et couper)
/// les puces et boutons d'Explorer et de Contacts. Au-delà de 1.3, le gain
/// de lisibilité ne compense plus des écrans illisibles ; en dessous de
/// 1.0, le texte devient trop petit pour le design.
class TextScaleClamp extends StatelessWidget {
  static const double min = 1.0;
  static const double max = 1.3;

  final Widget child;

  const TextScaleClamp({super.key, required this.child});

  /// Hauteur d'un bloc à hauteur fixe (carrousel, bouton) qui contient du
  /// texte : grandit avec la police du système au lieu de couper le texte.
  /// [textShare] : part de la hauteur occupée par du texte (le reste, image
  /// ou marges, ne grandit pas). Égal à [base] à l'échelle 1.0.
  static double grow(BuildContext context, double base, {double textShare = 0.5}) {
    final scale = MediaQuery.textScalerOf(context).scale(100) / 100;
    return (base * (1 + textShare * (scale - 1))).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(minScaleFactor: min, maxScaleFactor: max),
      ),
      child: child,
    );
  }
}

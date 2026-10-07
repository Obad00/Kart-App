import 'package:flutter/material.dart';

import '../utils/color_contrast.dart';

/// Initiales d'un avatar sans photo, dans la couleur d'accent — mais
/// toujours lisibles : au moins 4,5:1 avec le fond du rond, en thème clair
/// comme en thème sombre, quelle que soit la couleur d'accent.
///
/// Remonté sur l'écran Carte en mode sombre : avec un accent bleu marine,
/// les initiales « PS » étaient bleu foncé sur un rond bleu foncé sur fond
/// noir. La teinte de l'accent est conservée ; seule sa clarté est ajustée
/// quand il le faut.
class AvatarInitials extends StatelessWidget {
  final String initials;

  /// Couleur d'accent souhaitée pour les initiales.
  final Color accent;

  /// Fond réellement visible derrière les initiales. Si le rond est
  /// translucide, passer la couleur composée avec ce qu'il y a dessous
  /// (cf. [ColorContrast.composite]).
  final Color background;
  final double fontSize;

  const AvatarInitials({
    super.key,
    required this.initials,
    required this.accent,
    required this.background,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        color: ColorContrast.readableOn(accent, background),
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
      ),
    );
  }
}

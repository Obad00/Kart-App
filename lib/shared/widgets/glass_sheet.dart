import 'dart:ui';

import 'package:flutter/material.dart';

/// Fond "verre dépoli" pour les popups (bottom sheets, dialogs) — même
/// principe que GlassAppBar / StickyHeaderDelegate(blurBackground: true) :
/// BackdropFilter + léger tint de colorScheme.surface + bordure fine, pour
/// que toute l'app (barres, listes, popups) partage le même langage visuel
/// au lieu de Container(color: ...) opaques codés en dur.
class GlassSheet extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  // Par défaut colorScheme.outline (même bordure que les cartes/la pilule
  // de nav) — surchargeable pour un popup à identité visuelle propre (ex.
  // le rappel de complétion de profil, teinté ambre).
  final Color? borderColor;

  const GlassSheet({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(24)),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // RepaintBoundary : isole ce flou (BackdropFilter) + le texte qu'il
    // recouvre dans sa propre couche de composition — remonté côté produit
    // comme un artefact visuel jamais reproduit ici en rendu contrôlé
    // (golden test, même thème/police réels) : sur un device précis, un
    // flou composé directement avec du texte peut dans certains cas laisser
    // un liseré résiduel à la limite d'une passe de rendu. Isoler la couche
    // est la parade standard pour ce genre d'artefact, sans coût perceptible
    // ici (le contenu ne change pas à chaque frame).
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: isDark ? 0.75 : 0.85),
              borderRadius: borderRadius,
              border: Border.all(color: borderColor ?? colors.outline),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

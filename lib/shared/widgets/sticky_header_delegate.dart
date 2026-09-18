import 'dart:ui';

import 'package:flutter/material.dart';

/// Rend fixe (pinned) un bloc de contenu au sommet d'un CustomScrollView —
/// recherche/filtres, chips de statut... qui doivent rester visibles
/// pendant le scroll de la liste plutôt que de défiler avec elle. Fond en
/// verre dépoli (BackdropFilter) — même principe que GlassAppBar, pour un
/// rendu cohérent entre les pages à liste filtrable de l'app (Explorer,
/// Contacts...).
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  final bool blurBackground;

  StickyHeaderDelegate({
    required this.height,
    required this.child,
    this.blurBackground = false,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!blurBackground) {
      return Container(color: colors.surface, child: child);
    }

    // RepaintBoundary : isole ce flou dans sa propre couche de composition
    // — remonté côté produit comme un rognage visuel au bord d'un contenu
    // défilant HORIZONTALEMENT sous ce bandeau flouté (chips de "Mes
    // demandes"), jamais reproduit en rendu contrôlé. Même parade que pour
    // GlassSheet (cf. son commentaire), tentative sans coût perceptible ici.
    return RepaintBoundary(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: isDark ? 0.75 : 0.85),
              border: Border(
                bottom: BorderSide(
                  color: colors.onSurface.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.blurBackground != blurBackground;
  }
}

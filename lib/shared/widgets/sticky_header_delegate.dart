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

    return ClipRect(
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
    );
  }

  @override
  bool shouldRebuild(covariant StickyHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.child != child ||
        oldDelegate.blurBackground != blurBackground;
  }
}

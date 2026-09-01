import 'dart:ui';

import 'package:flutter/material.dart';

/// AppBar "verre dépoli" façon Apple (Liquid Glass / navigation bar iOS) —
/// remplaçant direct d'un AppBar classique. À utiliser avec
/// `Scaffold(extendBodyBehindAppBar: true, ...)` : sans ça, rien ne défile
/// derrière la barre et le flou n'a rien à flouter (elle ressemble alors à
/// une simple barre semi-transparente plate).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;

  const GlassAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            // Opacité volontairement basse — à 0.55/0.65 le tint écrasait le
            // flou et la barre paraissait juste comme un fond uni classique
            // (surtout en thème sombre, où le fond est déjà presque noir).
            // Un léger tint de la couleur de surface plutôt qu'un blanc/noir
            // plat — le verre dépoli d'Apple laisse toujours transparaître un
            // peu de la teinte du fond derrière lui.
            color: colors.surface.withValues(alpha: isDark ? 0.32 : 0.5),
            border: Border(
              bottom: BorderSide(
                color: colors.onSurface.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: AppBar(
            title: title,
            centerTitle: centerTitle,
            actions: actions,
            leading: leading,
            bottom: bottom,
            toolbarHeight: toolbarHeight,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
      ),
    );
  }
}

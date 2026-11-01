import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Affiche d'événement, quel que soit son format (A4 portrait, carré,
/// paysage) : l'image entière au premier plan, jamais recadrée, sur un fond
/// flou de la même image qui remplit le cadre. Même rendu que EventPoster.vue
/// côté site.
class PosterImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio;

  const PosterImage({super.key, required this.imageUrl, this.aspectRatio = 4 / 3});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24, tileMode: TileMode.clamp),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.25),
                colorBlendMode: BlendMode.darken,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            // CachedNetworkImage : l'affiche n'est pas retéléchargée à
            // chaque ouverture ; un loader comble le premier chargement.
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                color: Colors.white.withValues(alpha: 0.08),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
              ),
              // Une affiche qui ne charge pas ne doit pas casser la fiche.
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

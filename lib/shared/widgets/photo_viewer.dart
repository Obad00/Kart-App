import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Visualiseur plein écran pour une photo (avatar, logo...), comme dans les
/// applications modernes : fond noir, zoom au pincement, se ferme au tap ou
/// en balayant vers le bas.
class PhotoViewer extends StatelessWidget {
  final String imageUrl;

  const PhotoViewer({super.key, required this.imageUrl});

  static Future<void> show(BuildContext context, String imageUrl) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => PhotoViewer(imageUrl: imageUrl),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 250) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: [
            // Positioned.fill (plutôt que Center) donne des contraintes
            // bornées à l'InteractiveViewer : sans ça, Image.network se
            // dimensionne à la résolution native du fichier (souvent une
            // petite miniature), et BoxFit.contain n'a rien à agrandir —
            // d'où la photo minuscule constatée sur les avatars compressés.
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    // Cache disque : déjà vue (avatar de contact, de profil...)
                    // l'image plein écran s'affiche instantanément.
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white38, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

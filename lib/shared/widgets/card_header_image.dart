import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image principale d'une carte, la même règle que la page publique
/// (kart-vue-project, `useHeaderImage`) : la photo de profil ; à défaut
/// (absente, ou qui ne se charge pas) le logo de l'entreprise ; à défaut
/// les initiales. Jamais la photo et le logo côte à côte.
///
/// [initials] reste affiché tant qu'aucune image n'est chargée : jamais
/// d'image cassée ni de cadre vide.
class CardHeaderImage extends StatelessWidget {
  const CardHeaderImage({
    super.key,
    required this.size,
    required this.initials,
    this.avatarUrl,
    this.logoUrl,
    this.radius,
    this.backgroundColor = initialsBackground,
    this.imageProvider = _network,
  });

  /// Fond des initiales par défaut : le bleu nuit de la page publique.
  static const initialsBackground = Color(0xFF0E2A57);

  /// Fond crème derrière le logo, toujours affiché entier.
  static const logoBackground = Color(0xFFF6F3EC);

  final double size;

  /// Rayon des coins ; null = rond.
  final double? radius;
  final String? avatarUrl;
  final String? logoUrl;

  /// Affiché sans photo ni logo (déjà mis en forme par l'appelant).
  final Widget initials;
  final Color backgroundColor;

  /// Remplaçable dans les tests.
  final ImageProvider Function(String url) imageProvider;

  static ImageProvider _network(String url) => CachedNetworkImageProvider(url);

  bool get _round => radius == null || radius! * 2 >= size;

  @override
  Widget build(BuildContext context) {
    final avatar = (avatarUrl ?? '').trim();
    final logo = (logoUrl ?? '').trim();

    // Logo entier (`contain`) sur fond crème ; dans un rond, assez de marge
    // pour qu'il y tienne.
    Widget logoImage() => Image(
          key: const Key('header-image-logo'),
          image: imageProvider(logo),
          fit: BoxFit.contain,
          frameBuilder: (_, child, frame, __) => frame == null
              ? const SizedBox.shrink()
              : Container(
                  color: logoBackground,
                  padding: EdgeInsets.all(size * (_round ? 0.14 : 0.08)),
                  child: child,
                ),
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor, child: Center(child: initials)),
            if (avatar.isNotEmpty)
              Image(
                key: const Key('header-image-avatar'),
                image: imageProvider(avatar),
                fit: BoxFit.cover,
                // La photo ne se charge pas : le logo, s'il y en a un.
                errorBuilder: (_, __, ___) =>
                    logo.isEmpty ? const SizedBox.shrink() : logoImage(),
              )
            else if (logo.isNotEmpty)
              logoImage(),
          ],
        ),
      ),
    );
  }
}

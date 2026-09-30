import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import 'kart_card_faces.dart';

/// Carte de visite retournable : une face principale au premier plan et
/// l'autre face qui dépasse derrière, à droite — un tap sur cette partie
/// visible retourne la carte (rotation Y). Les deux faces ont exactement la
/// même taille (KartCardSurface).
///
/// L'état (quelle face, progression de la rotation) est piloté par
/// [animation] (0 = face QR, 1 = face infos), possédée par la page : le
/// bouton sous la carte et les points utilisent la même source.
class KartFlipCard extends StatelessWidget {
  final double width;
  final Animation<double> animation;
  final Widget qrFace;
  final Widget infoFace;

  /// Version non interactive de chaque face, affichée derrière.
  final Widget qrFacePeek;
  final Widget infoFacePeek;

  final VoidCallback onFlip;

  const KartFlipCard({
    super.key,
    required this.width,
    required this.animation,
    required this.qrFace,
    required this.infoFace,
    required this.qrFacePeek,
    required this.infoFacePeek,
    required this.onFlip,
  });

  /// Largeur de la carte pour un écran donné : laisse la place à la face
  /// qui dépasse à droite, plafonnée pour les grands écrans.
  static double widthFor(double screenWidth) =>
      math.min(screenWidth - 72, 330).toDouble();

  /// Partie de la face arrière qui dépasse à droite.
  static double peekFor(double width) => width * 0.12;

  @override
  Widget build(BuildContext context) {
    final height = width * kartCardAspect;
    final peek = peekFor(width);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final angle = t * math.pi;
        final showingInfo = t >= 0.5;

        final front = showingInfo
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: infoFace,
              )
            : qrFace;

        return SizedBox(
          width: width + peek,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Autre face, derrière, légèrement inclinée et décalée à droite.
              Positioned(
                left: peek,
                top: 0,
                child: Semantics(
                  button: true,
                  label: showingInfo ? 'Afficher le QR' : 'Afficher la carte',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFlip,
                    child: Transform.rotate(
                      angle: 0.06,
                      child: Transform.scale(
                        scale: 0.92,
                        // Ancrée à droite : la face réduite dépasse de
                        // [peek] à droite de la face principale.
                        alignment: Alignment.centerRight,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.92,
                            child: showingInfo ? qrFacePeek : infoFacePeek,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Face principale, rotation Y avec perspective.
              Positioned(
                left: 0,
                top: 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: front,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bouton sous la carte : "Afficher la carte" (face QR affichée) ou
/// "Afficher le QR" (face infos affichée), avec icône de retournement.
class KartFlipButton extends StatelessWidget {
  final bool showingInfo;
  final VoidCallback onTap;

  const KartFlipButton({
    super.key,
    required this.showingInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Material(
      color: t.buttonBackground,
      shape: StadiumBorder(side: BorderSide(color: t.softBorder)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync_rounded, size: 20, color: t.textPrimary),
              const SizedBox(width: 10),
              Text(
                showingInfo ? 'Afficher le QR' : 'Afficher la carte',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Deux points : face QR / face infos. Un tap sur un point affiche la face
/// correspondante.
class KartFaceIndicator extends StatelessWidget {
  final bool showingInfo;
  final ValueChanged<bool> onSelect;

  const KartFaceIndicator({
    super.key,
    required this.showingInfo,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    Widget dot(bool isInfo) {
      final active = isInfo == showingInfo;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(isInfo),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? t.textPrimary : t.softBorder,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: showingInfo ? 'Face infos affichée' : 'Face QR affichée',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [dot(false), dot(true)],
      ),
    );
  }
}

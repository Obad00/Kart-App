import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import 'kart_card_faces.dart';

/// Carte de visite à deux faces : une face au premier plan et l'autre qui
/// dépasse derrière, à droite. Changer de face fait passer la carte de
/// devant derrière pendant que celle de derrière avance au premier plan
/// (échange façon paquet de cartes), en suivant le doigt pendant un swipe.
/// Les deux faces ont exactement la même taille (KartCardSurface).
///
/// L'état est piloté par [animation] (0 = face QR devant, 1 = face infos
/// devant), possédée par la page : le bouton sous la carte, les points et
/// le swipe utilisent la même source.
class KartFlipCard extends StatelessWidget {
  final double width;
  final Animation<double> animation;
  final Widget qrFace;
  final Widget infoFace;

  /// Version non interactive de chaque face, affichée derrière.
  final Widget qrFacePeek;
  final Widget infoFacePeek;

  final VoidCallback onFlip;

  /// Swipe horizontal sur la face principale : la carte suit le doigt.
  /// [onDragUpdate] reçoit le déplacement horizontal, [onDragEnd] la
  /// vitesse horizontale au lâcher.
  final ValueChanged<double>? onDragUpdate;
  final ValueChanged<double>? onDragEnd;

  /// Sens de départ de la carte de devant pendant l'échange : -1 vers la
  /// gauche (défaut : bouton, points, tap), +1 vers la droite (swipe vers
  /// la droite) — la carte part dans le sens du doigt.
  final double swipeDirection;

  /// Face qui était devant au début de l'échange en cours : c'est elle qui
  /// part (grand arc + inclinaison), l'autre avance.
  final bool swapFromInfo;

  const KartFlipCard({
    super.key,
    required this.width,
    required this.animation,
    required this.qrFace,
    required this.infoFace,
    required this.qrFacePeek,
    required this.infoFacePeek,
    required this.onFlip,
    this.onDragUpdate,
    this.onDragEnd,
    this.swipeDirection = -1,
    this.swapFromInfo = false,
  });

  /// Largeur de la carte pour un écran donné : laisse la place à la face
  /// qui dépasse à droite, plafonnée pour les grands écrans.
  static double widthFor(double screenWidth) =>
      (screenWidth * 0.72).clamp(240.0, 300.0);

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
        final qrInFront = t < 0.5;
        // Arc de l'échange : 0 aux extrémités, 1 au milieu.
        final arc = math.sin(math.pi * t);
        final dir = swipeDirection < 0 ? -1.0 : 1.0;

        // Carte qui part (celle de devant au début de l'échange) : glisse
        // dans le sens du geste, s'incline légèrement en 3D, puis va se
        // ranger derrière, à droite.
        Widget leaving(Widget child, double p) => _posed(
              child: child,
              dx: peek * p + dir * arc * width * 0.42,
              scale: 1 - 0.08 * p,
              angle: 0.06 * p + dir * arc * 0.10,
              tiltY: -dir * arc * 0.35,
            );

        // Carte qui avance (celle de derrière au début) : vient prendre la
        // place de devant avec un léger décalage opposé au geste.
        Widget coming(Widget child, double p) => _posed(
              child: child,
              dx: peek * (1 - p) - dir * arc * width * 0.12,
              scale: 0.92 + 0.08 * p,
              angle: 0.06 * (1 - p) - dir * arc * 0.04,
            );

        // Les gestes sont posés DANS la transformation de chaque carte :
        // la zone de tap suit ainsi la carte là où elle est dessinée (la
        // partie de derrière qui dépasse à droite reste cliquable).
        Widget asBack(Widget face) => Semantics(
              button: true,
              label: qrInFront ? 'Afficher la carte' : 'Afficher le QR',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onFlip,
                child: IgnorePointer(child: face),
              ),
            );
        Widget asFront(Widget face) => face;

        // p : avancement de l'échange en cours (0 = début, 1 = fin), quel
        // que soit le sens (QR -> infos ou infos -> QR).
        final p = swapFromInfo ? 1 - t : t;
        final qrWidget = qrInFront ? asFront(qrFace) : asBack(qrFacePeek);
        final infoWidget = qrInFront ? asBack(infoFacePeek) : asFront(infoFace);
        final qrCard =
            swapFromInfo ? coming(qrWidget, p) : leaving(qrWidget, p);
        final infoCard =
            swapFromInfo ? leaving(infoWidget, p) : coming(infoWidget, p);

        // Swipe détecté sur toute la zone des cartes (fixe) plutôt que sur
        // la carte de devant : les cartes échangent leur ordre à mi-course,
        // ce qui aurait interrompu le geste en cours.
        return GestureDetector(
          onHorizontalDragUpdate:
              onDragUpdate == null ? null : (d) => onDragUpdate!(d.delta.dx),
          onHorizontalDragEnd: onDragEnd == null
              ? null
              : (d) => onDragEnd!(d.velocity.pixelsPerSecond.dx),
          child: SizedBox(
            width: width + peek,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              // La carte de devant est peinte en dernier (au-dessus).
              children: qrInFront ? [infoCard, qrCard] : [qrCard, infoCard],
            ),
          ),
        );
      },
    );
  }

  /// Place une face selon sa pose (décalage, échelle ancrée à droite,
  /// inclinaison) dans la zone commune aux deux cartes.
  Widget _posed({
    required Widget child,
    required double dx,
    required double scale,
    required double angle,
    double tiltY = 0,
  }) {
    return Transform.translate(
      offset: Offset(dx, 0),
      // Légère inclinaison 3D (rotation Y avec perspective) de la carte qui
      // part, maximale au milieu de l'échange.
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(tiltY),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            // Ancrée à droite : en pose "derrière", la face réduite dépasse
            // de [peek] à droite de la face de devant.
            alignment: Alignment.centerRight,
            // Cartes opaques : aucune transparence, pour qu'on ne voie jamais
            // le texte de celle de derrière à travers celle de devant.
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Bouton sous la carte : "Afficher la carte" (face QR affichée) ou
/// "Afficher le QR" (face infos affichée), avec icône de retournement.
class KartFlipButton extends StatelessWidget {
  final bool showingInfo;
  final VoidCallback onTap;

  /// Avancement de l'échange (0 à 1) : l'icône fait un demi-tour en suivant
  /// le mouvement des cartes (bouton, points ou swipe).
  final double progress;

  const KartFlipButton({
    super.key,
    required this.showingInfo,
    required this.onTap,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    // Même fond et même contour (couleur + 1 px) que les boutons d'action
    // ronds (CardQuickActions) : l'ensemble sous la carte reste homogène.
    return Material(
      color: t.softFill,
      shape: StadiumBorder(side: BorderSide(color: t.buttonStroke, width: 1)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: progress * math.pi,
                child: Icon(Icons.sync_rounded, size: 20, color: t.textPrimary),
              ),
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

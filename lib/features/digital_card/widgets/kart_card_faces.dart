import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import '../../../shared/widgets/shrink_to_fit_text.dart';
import 'brushed_texture.dart';
import 'kart_card_data.dart';

/// Largeur de référence des maquettes : les tailles internes de la carte
/// (marges, polices, logo) sont proportionnelles à la largeur réelle, pour
/// garder les mêmes proportions de l'iPhone SE au Pro Max.
const double _refWidth = 330;

/// Ratio hauteur/largeur de la carte (portrait, maquette 1) — commun aux
/// deux faces.
const double kartCardAspect = 1.18;

/// Support commun des deux faces : noir mat, texture brossée, rayon 20,
/// contour gris foncé en thème sombre, une seule ombre douce. Les deux faces
/// passent par ce widget avec la même taille : elles ne peuvent pas diverger.
class KartCardSurface extends StatelessWidget {
  final double width;
  final Widget child;
  final bool withShadow;

  /// Couleur qui teinte le fond (cf. KartCardData.tint) ; null = noir mat.
  final Color? tint;

  const KartCardSurface({
    super.key,
    required this.width,
    required this.child,
    this.withShadow = true,
    this.tint,
  });

  static const double radius = 20;

  /// Nuance sombre de [color] à la luminosité [lightness] : garde la teinte,
  /// plafonne la saturation — une couleur vive (jaune, cyan...) donne ainsi
  /// un fond sombre élégant sur lequel le texte clair reste lisible.
  static Color _shade(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(math.min(hsl.saturation, 0.55))
        .withLightness(lightness)
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final shape = BorderRadius.circular(radius);

    // Sans couleur choisie : noir mat (tokens). Avec : mêmes reliefs métal,
    // dans une nuance sombre de la couleur.
    final base = tint == null ? t.cardBlack : _shade(tint!, 0.13);
    final sheen = tint == null ? t.cardSheen : _shade(tint!, 0.20);
    final deep = tint == null ? t.cardDeep : _shade(tint!, 0.07);

    return Container(
      width: width,
      height: width * kartCardAspect,
      decoration: BoxDecoration(
        color: base,
        // Effet métal : très léger dégradé diagonal, sans reflet brillant.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sheen, base, deep],
          stops: const [0.0, 0.45, 1.0],
        ),
        borderRadius: shape,
        border: Border.all(color: t.cardBorder, width: 1),
        boxShadow: withShadow
            ? [
                BoxShadow(
                  color: t.cardShadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BrushedTexture(lightStroke: t.onCard, darkStroke: base),
            // Filigrane "K" très discret, entier, en bas à droite.
            Positioned(
              right: width * 0.05,
              bottom: -width * 0.04,
              child: Text(
                'K',
                style: TextStyle(
                  color: t.onCard.withValues(alpha: 0.045),
                  fontSize: width * 0.55,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            // Fin liseré lumineux sur le bord supérieur (tranche métal).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      t.onCard.withValues(alpha: 0),
                      t.onCard.withValues(alpha: 0.14),
                      t.onCard.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Face QR (affichée par défaut) : logo, "KART", nom, titre, grand QR sur
/// fond blanc, point vert + "Scannez pour me contacter".
class KartCardQrFace extends StatelessWidget {
  final double width;
  final KartCardData data;
  final Widget qr;

  /// Clé du RepaintBoundary du bloc QR complet (export "Télécharger").
  final GlobalKey? captureKey;

  /// Tap sur la carte en dehors du QR (le QR garde son propre geste).
  final VoidCallback? onTapCard;

  const KartCardQrFace({
    super.key,
    required this.width,
    required this.data,
    required this.qr,
    this.captureKey,
    this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = width / _refWidth;

    final face = KartCardSurface(
      width: width,
      tint: data.tint,
      child: Padding(
        padding: EdgeInsets.all(24 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTopRow(data: data, scale: s),
            SizedBox(height: 16 * s),
            _NameBlock(data: data, scale: s),
            SizedBox(height: 12 * s),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Place réservée à la ligne "Scannez pour me contacter".
                  final footer = 30 * s;
                  final side =
                      (c.maxHeight - footer).clamp(0.0, width * 0.58);
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: side,
                            height: side,
                            padding: EdgeInsets.all(side * 0.07),
                            decoration: BoxDecoration(
                              color: t.qrBackground,
                              borderRadius: BorderRadius.circular(16 * s),
                            ),
                            child: qr,
                          ),
                        ),
                      ),
                      SizedBox(height: 10 * s),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8 * s,
                            height: 8 * s,
                            decoration: BoxDecoration(
                              color: t.positive,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8 * s),
                          Flexible(
                            child: Text(
                              'Scannez pour me contacter',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.onCard,
                                fontSize: 12.5 * s,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    final tappable = onTapCard == null
        ? face
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapCard,
            child: face,
          );
    if (captureKey == null) return tappable;
    return RepaintBoundary(key: captureKey, child: tappable);
  }
}

/// Face infos : logo, "KART", nom, titre, puis les lignes de contact
/// (téléphone, email, ville) — chacune seulement si elle est renseignée.
class KartCardInfoFace extends StatelessWidget {
  final double width;
  final KartCardData data;

  const KartCardInfoFace({
    super.key,
    required this.width,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final s = width / _refWidth;

    final lines = <Widget>[
      if (data.hasPhone)
        _ContactLine(icon: Icons.phone_outlined, text: data.phone!, scale: s),
      if (data.hasEmail)
        _ContactLine(icon: Icons.mail_outline, text: data.email!, scale: s),
      if (data.hasCity)
        _ContactLine(
            icon: Icons.location_on_outlined, text: data.city!, scale: s),
    ];

    return KartCardSurface(
      width: width,
      tint: data.tint,
      child: Padding(
        padding: EdgeInsets.all(24 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTopRow(data: data, scale: s),
            SizedBox(height: 28 * s),
            _NameBlock(data: data, scale: s),
            const Spacer(),
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) SizedBox(height: 12 * s),
              lines[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne du haut de la carte : logo, nom de l'entreprise, « KART ».
///
/// Deux dispositions pour le nom, pour qu'il ne soit jamais coupé tant que
/// l'une des deux suffit (cas réel : « Cabinet Médical Ahmadina Saliou
/// (CMAS) », tronqué à côté du logo) :
///  - A, par défaut : à côté du logo, sur 3 lignes au plus, réduit si besoin
///    jusqu'à la taille minimale ;
///  - B, en repli : si même à la taille minimale il ne tient pas à côté du
///    logo (nom très long, logo large), il passe sur sa propre ligne, pleine
///    largeur, sur 2 lignes.
/// Les « … » n'apparaissent que si B ne suffit pas non plus.
class _CardTopRow extends StatefulWidget {
  final KartCardData data;
  final double scale;

  const _CardTopRow({required this.data, required this.scale});

  @override
  State<_CardTopRow> createState() => _CardTopRowState();
}

class _CardTopRowState extends State<_CardTopRow> {
  /// true une fois constaté que le nom ne tient pas à côté du logo.
  bool _nameBelow = false;

  static const int _linesBeside = 3;
  static const int _linesBelow = 2;

  @override
  void didUpdateWidget(_CardTopRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Autre nom, autre logo ou autre taille de carte : on réévalue.
    if (oldWidget.data.brandName != widget.data.brandName ||
        oldWidget.data.logoFullUrl != widget.data.logoFullUrl ||
        oldWidget.data.logoUrl != widget.data.logoUrl ||
        oldWidget.scale != widget.scale) {
      _nameBelow = false;
    }
  }

  TextStyle _nameStyle(KartTokens t, double fontSize) => TextStyle(
        color: t.onCard,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        height: 1.25,
      );

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = widget.scale;
    final data = widget.data;
    final name = data.hasBrandName ? data.brandName!.toUpperCase() : null;
    final minSize = 9 * s;
    final style = _nameStyle(t, 11.5 * s);

    // Compte entreprise : le badge (ex: PRO) prend la place de "KART".
    final Widget mark = data.badgeLabel != null
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6 * s),
              border: Border.all(color: t.onCard.withValues(alpha: 0.6)),
            ),
            child: Text(
              data.badgeLabel!,
              style: TextStyle(
                color: t.onCard,
                fontSize: 12 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          )
        : Text(
            'KART',
            style: TextStyle(
              color: t.onCard,
              fontSize: 17 * s,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          );

    final logo = _LogoTile(data: data, size: 34 * s);

    // Disposition B : logo et « KART » en haut, le nom dessous.
    if (name != null && _nameBelow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [logo, const Spacer(), SizedBox(width: 12 * s), mark]),
          SizedBox(height: 8 * s),
          ShrinkToFitText(
            name,
            maxLines: _linesBelow,
            minFontSize: minSize,
            style: style,
          ),
        ],
      );
    }

    // Disposition A : le nom à côté du logo.
    return Row(
      children: [
        logo,
        if (name != null) ...[
          SizedBox(width: 10 * s),
          Expanded(
            // La largeur restante n'est connue qu'ici, une fois le logo
            // mesuré (elle dépend de son ratio, donc de l'image chargée).
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fitsBeside = ShrinkToFitText.fits(
                  context,
                  text: name,
                  style: style.copyWith(fontSize: minSize),
                  maxLines: _linesBeside,
                  maxWidth: constraints.maxWidth,
                );
                if (!fitsBeside) {
                  // On ne peut pas changer de disposition pendant la mise
                  // en page : on le fait juste après.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_nameBelow) {
                      setState(() => _nameBelow = true);
                    }
                  });
                }
                return ShrinkToFitText(
                  name,
                  maxLines: _linesBeside,
                  minFontSize: minSize,
                  style: style,
                );
              },
            ),
          ),
        ] else
          const Spacer(),
        SizedBox(width: 12 * s),
        mark,
      ],
    );
  }
}

class _LogoTile extends StatelessWidget {
  final KartCardData data;
  final double size;

  const _LogoTile({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final radius = data.logoIsPhoto
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(size * 0.28);

    final initialSource =
        data.hasBrandName ? data.brandName!.trim() : data.fullName.trim();
    final placeholder = Container(
      color: t.onCard.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Text(
        initialSource.isNotEmpty ? initialSource[0].toUpperCase() : 'K',
        style: TextStyle(
          color: t.onCard,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (data.hasFullLogo) {
      return _FullLogo(data: data, size: size, fallback: placeholder);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: t.onCard.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: data.hasLogo
            ? CachedNetworkImage(
                imageUrl: data.logoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}

/// Logo entier, jamais coupé : même hauteur que la tuile carrée, mais la
/// largeur suit le ratio du logo (jusqu'à [_maxAspect] fois la hauteur), et
/// l'image est en `BoxFit.contain`. Un logo opaque (fond blanc le plus
/// souvent) est posé dans une pastille claire : collé tel quel sur la carte
/// noire, il ferait un rectangle blanc peu élégant.
class _FullLogo extends StatelessWidget {
  final KartCardData data;
  final double size;
  final Widget fallback;

  const _FullLogo({
    required this.data,
    required this.size,
    required this.fallback,
  });

  /// Largeur max = 2,6 × la hauteur : un logo très allongé reste entier
  /// (il rétrécit), sans pousser le nom de l'entreprise hors de la carte.
  static const double _maxAspect = 2.6;

  /// Blanc cassé de la pastille (pas un blanc pur, trop dur sur le noir).
  static const Color _pill = Color(0xFFF7F5F0);

  @override
  Widget build(BuildContext context) {
    final onPill = data.logoTransparent == false;
    final radius = BorderRadius.circular(math.min(12.0, size * 0.35));
    final padding = onPill ? size * 0.12 : 0.0;
    final inner = size - 2 * padding;

    final image = Image(
      image: data.logoFullProvider,
      height: inner,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      // Tant que l'image charge (ou si elle échoue), un carré de la taille
      // de la tuile habituelle tient la place.
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
          frame == null && !wasSynchronouslyLoaded
              ? SizedBox(width: inner, height: inner)
              : child,
      errorBuilder: (_, __, ___) =>
          SizedBox(width: inner, height: inner, child: fallback),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: size,
        maxWidth: size * _maxAspect,
        minHeight: size,
        maxHeight: size,
      ),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: onPill
            ? BoxDecoration(color: _pill, borderRadius: radius)
            : null,
        child: image,
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  final KartCardData data;
  final double scale;

  const _NameBlock({required this.data, required this.scale});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Noms longs : jusqu'à 2 lignes et police réduite plutôt que "…".
        Text(
          data.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: t.onCard,
            fontSize: (data.fullName.length > 16 ? 20 : 24) * s,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        if (data.hasJobTitle) ...[
          SizedBox(height: 8 * s),
          Text(
            data.jobTitle!.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.onCardMuted,
              fontSize: 10.5 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final double scale;

  const _ContactLine({
    required this.icon,
    required this.text,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = scale;

    return Row(
      children: [
        Icon(icon, size: 18 * s, color: t.onCardMuted),
        SizedBox(width: 12 * s),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.onCard,
              fontSize: 13.5 * s,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

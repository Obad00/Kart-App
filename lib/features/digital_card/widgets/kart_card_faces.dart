import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
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

  const KartCardSurface({
    super.key,
    required this.width,
    required this.child,
    this.withShadow = true,
  });

  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final shape = BorderRadius.circular(radius);

    return Container(
      width: width,
      height: width * kartCardAspect,
      decoration: BoxDecoration(
        color: t.cardBlack,
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
            BrushedTexture(lightStroke: t.onCard, darkStroke: t.cardBlack),
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

  const KartCardQrFace({
    super.key,
    required this.width,
    required this.data,
    required this.qr,
    this.captureKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = width / _refWidth;

    final face = KartCardSurface(
      width: width,
      child: Padding(
        padding: EdgeInsets.all(24 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTopRow(data: data, scale: s),
            SizedBox(height: 18 * s),
            _NameBlock(data: data, scale: s),
            SizedBox(height: 14 * s),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  // Place réservée à la ligne "Scannez pour me contacter".
                  final footer = 30 * s;
                  final side =
                      (c.maxHeight - footer).clamp(0.0, width * 0.56);
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

    if (captureKey == null) return face;
    return RepaintBoundary(key: captureKey, child: face);
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

class _CardTopRow extends StatelessWidget {
  final KartCardData data;
  final double scale;

  const _CardTopRow({required this.data, required this.scale});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final s = scale;

    return Row(
      children: [
        _LogoTile(data: data, size: 34 * s),
        if (data.hasBrandName) ...[
          SizedBox(width: 10 * s),
          Flexible(
            child: Text(
              data.brandName!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.onCard,
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ] else
          const Spacer(),
        SizedBox(width: 12 * s),
        if (data.badgeLabel != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6 * s),
              border: Border.all(color: t.onCardMuted.withValues(alpha: 0.5)),
            ),
            child: Text(
              data.badgeLabel!,
              style: TextStyle(
                color: t.onCardMuted,
                fontSize: 9 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(width: 8 * s),
        ],
        Text(
          'KART',
          style: TextStyle(
            color: t.onCard,
            fontSize: 17 * s,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
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
        Text(
          data.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: t.onCard,
            fontSize: 25 * s,
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

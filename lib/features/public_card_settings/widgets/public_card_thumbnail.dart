import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/card_header_image.dart';
import '../models/public_card_settings.dart';
import '../public_card_styles.dart';
import 'public_card_next_view.dart';

/// Haut de la page publique pour une disposition, dessiné d'après les
/// dispositions du site en ligne (LayoutPhysical / LayoutClassic /
/// LayoutBanner, main 7e566a0). Toutes les tailles sont celles du site,
/// multipliées par [width] / 358 (largeur du contenu sur un téléphone).
///
/// Avec [identity] : vrais textes (aperçu en direct). Sans : traits
/// (vignettes du carrousel).
class PublicCardHero extends StatelessWidget {
  const PublicCardHero({
    super.key,
    required this.width,
    required this.settings,
    required this.accent,
    this.identity,
  });

  final double width;
  final PublicCardSettings settings;
  final EffectiveAccent accent;
  final PreviewIdentity? identity;

  double get _u => width / 358;

  @override
  Widget build(BuildContext context) {
    final p = PublicPagePalette.of(settings.theme);
    return SizedBox(
      width: width,
      child: switch (settings.layout) {
        'classic' => _classic(p),
        'banner' => _banner(p),
        _ => _physical(p),
      },
    );
  }

  Widget _text(String value, double size, Color color,
          {FontWeight weight = FontWeight.w400, bool syne = false, TextAlign? align}) =>
      Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: TextStyle(
          fontFamily: syne ? 'Syne' : 'Archivo',
          fontSize: size * _u,
          fontWeight: weight,
          color: color,
          height: 1.2,
        ),
      );

  Widget _bar(double w, double h, Color color) => Container(
        width: w * _u,
        height: h * _u,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(h * _u / 2),
        ),
      );

  /// Nom, poste, « entreprise · ville » — textes, ou traits de même place.
  List<Widget> _identityLines({
    required Color text,
    required Color muted,
    required double nameSize,
    required double jobSize,
    bool centered = false,
  }) {
    final id = identity;
    final align = centered ? TextAlign.center : TextAlign.start;
    if (id == null) {
      return [
        _bar(170, nameSize * 0.72, text),
        SizedBox(height: 10 * _u),
        _bar(120, jobSize * 0.6, text.withValues(alpha: 0.8)),
        SizedBox(height: 8 * _u),
        _bar(150, jobSize * 0.6, muted),
      ];
    }
    return [
      _text(id.fullName, nameSize, text, weight: FontWeight.w800, syne: true, align: align),
      if (id.jobTitle.isNotEmpty) ...[
        SizedBox(height: 4 * _u),
        _text(id.jobTitle, jobSize, text, weight: FontWeight.w500, align: align),
      ],
      if (id.companyLine.isNotEmpty) ...[
        SizedBox(height: 4 * _u),
        _text(id.companyLine, 14, muted, align: align),
      ],
    ];
  }

  /// Image du haut, dans un rond : la photo, sinon le logo, sinon les
  /// initiales (cf. [CardHeaderImage]). Vignettes : un rond uni.
  /// [withLogo] à false : photo, sinon initiales (Carte physique, où le
  /// logo est déjà affiché à gauche).
  Widget _avatar(double size,
          {required Color background, required Color foreground, bool withLogo = true}) =>
      CardHeaderImage(
        size: size * _u,
        avatarUrl: identity?.avatarUrl,
        logoUrl: withLogo ? identity?.logoUrl : null,
        backgroundColor: background,
        initials: identity == null
            ? const SizedBox.shrink()
            : Text(
                identity!.initials,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.36 * _u,
                  color: foreground,
                ),
              ),
      );

  // ── Carte physique : carte inclinée de la couleur d'accent derrière ;
  //    devant, le logo de l'entreprise (ou « KART ») en haut à gauche, la
  //    photo (ou les initiales) dans un rond en haut à droite, puis nom,
  //    poste, entreprise. Seule disposition où le logo et la photo sont
  //    tous deux en haut, comme sur une vraie carte de visite.
  Widget _physical(PublicPagePalette p) {
    final look = PublicCardStyles.cardLook(settings.cardStyle, accent.color);
    final radius = BorderRadius.circular(PublicCardStyles.cardRadius * _u);

    return Padding(
      padding: EdgeInsets.only(top: 14 * _u),
      child: Stack(
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: PublicCardStyles.backCardAngle,
              child: Container(
                decoration: BoxDecoration(
                  color: look.back.withValues(alpha: 0.9),
                  borderRadius: radius,
                  border: Border.all(color: look.border),
                ),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: 208 * _u),
            padding: EdgeInsets.all(20 * _u),
            decoration: BoxDecoration(
              gradient: look.gradient,
              borderRadius: radius,
              border: Border.all(color: look.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x8C000000),
                  blurRadius: 40 * _u,
                  spreadRadius: -18 * _u,
                  offset: Offset(0, 18 * _u),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: identity == null
                            ? _bar(54, 9, look.muted)
                            : _cardLogo(look.muted),
                      ),
                    ),
                    _avatar(52,
                        background: look.avatarBackground,
                        foreground: look.avatarText,
                        withLogo: false),
                  ],
                ),
                SizedBox(height: 46 * _u),
                ..._identityLines(text: look.text, muted: look.muted, nameSize: 26, jobSize: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Haut gauche de la carte physique : le logo de l'entreprise, entier,
  /// sur 34 px de haut (dans une pastille claire s'il est opaque) ; sans
  /// logo, ou s'il ne se charge pas, le mot « KART ».
  Widget _cardLogo(Color muted) {
    final kart = Text(
      'KART',
      style: TextStyle(
        fontFamily: 'Syne',
        fontWeight: FontWeight.w800,
        fontSize: 13 * _u,
        letterSpacing: 3 * _u,
        color: muted,
      ),
    );
    final url = (identity?.logoUrl ?? '').trim();
    if (url.isEmpty) return kart;

    final onPill = identity!.logoOnPill;
    return Image(
      key: const Key('physical-card-logo'),
      image: CachedNetworkImageProvider(url),
      height: 34 * _u,
      fit: BoxFit.contain,
      frameBuilder: (_, child, frame, __) => frame == null
          ? kart
          : Container(
              constraints: BoxConstraints(maxWidth: 34 * 2.6 * _u),
              padding: EdgeInsets.all(onPill ? 4 * _u : 0),
              decoration: BoxDecoration(
                color: onPill ? const Color(0xFFF7F5F0) : null,
                borderRadius: BorderRadius.circular(10 * _u),
              ),
              child: child,
            ),
      errorBuilder: (_, __, ___) => kart,
    );
  }

  // ── Classique : photo ronde et nom centrés.
  Widget _classic(PublicPagePalette p) => Padding(
        padding: EdgeInsets.only(top: 8 * _u),
        child: Column(
          children: [
            _avatar(104, background: accent.color, foreground: accent.onColor),
            SizedBox(height: 16 * _u),
            ..._identityLines(text: p.text, muted: p.muted, nameSize: 28, jobSize: 15, centered: true),
          ],
        ),
      );

  // ── Bandeau : bande de la couleur d'accent, photo ronde à cheval
  //    dessus (liseré de la couleur du fond), nom à gauche.
  Widget _banner(PublicPagePalette p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: (128 + 56) * _u,
            child: Stack(
              children: [
                Container(
                  height: 128 * _u,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.color, Color.lerp(accent.color, Colors.black, 0.45)!],
                    ),
                    borderRadius: BorderRadius.circular(20 * _u),
                  ),
                ),
                Positioned(
                  left: 16 * _u,
                  top: 80 * _u,
                  child: Container(
                    padding: EdgeInsets.all(4 * _u),
                    decoration: BoxDecoration(color: p.background, shape: BoxShape.circle),
                    child: _avatar(96, background: accent.color, foreground: accent.onColor),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12 * _u),
          ..._identityLines(text: p.text, muted: p.muted, nameSize: 28, jobSize: 15),
        ],
      );
}

/// Ce que l'aperçu en direct écrit : les vraies infos de la carte.
class PreviewIdentity {
  const PreviewIdentity({
    required this.fullName,
    this.jobTitle = '',
    this.company = '',
    this.city = '',
    this.phone = '',
    this.avatarUrl,
    this.logoUrl,
    this.logoOnPill = true,
  });

  final String fullName;
  final String jobTitle;
  final String company;
  final String city;

  /// Numéro écrit sous « Appeler » (bento).
  final String phone;

  /// Photo de profil : l'image du haut de la carte quand elle existe.
  final String? avatarUrl;

  /// Logo de l'entreprise : affiché à la place de la photo quand il n'y en
  /// a pas (ou qu'elle ne se charge pas). Sans l'un ni l'autre : initiales.
  /// Sur la Carte physique, il reste en haut à gauche de la carte.
  final String? logoUrl;

  /// Logo opaque (fond blanc le plus souvent) : posé dans une pastille
  /// claire sur la carte physique. false = logo transparent, posé tel quel.
  final bool logoOnPill;

  String get companyLine => [company, city].where((v) => v.trim().isNotEmpty).join(' · ');

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.length > 1 ? '${parts.first[0]}${parts.last[0]}' : parts.first[0]).toUpperCase();
  }
}

/// Vignette d'une disposition (96 × 150) : la page en petit — haut de la
/// disposition, bouton « Enregistrer le contact », deux cartes de contact.
/// Bento et Éditorial : la page telle qu'elle s'ouvre sur téléphone, avec
/// leur bouton fixé en bas.
class PublicCardThumbnail extends StatelessWidget {
  const PublicCardThumbnail({
    super.key,
    required this.settings,
    required this.accent,
    this.width = 96,
    this.height = 150,
  });

  final PublicCardSettings settings;
  final EffectiveAccent accent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = PublicPagePalette.of(settings.theme);
    final pad = width * 8 / 96;
    final inner = width - 2 * pad;
    if (PublicCardSettings.nextLayouts.contains(settings.layout)) {
      return _next(pad, inner);
    }
    final u = inner / 358;

    return Container(
      width: width,
      height: height,
      color: p.background,
      padding: EdgeInsets.all(pad),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              PublicCardHero(width: inner, settings: settings, accent: accent),
              SizedBox(height: 20 * u),
              // « Enregistrer le contact » : 56 px, rayon 16, fond accent.
              Container(
                height: 56 * u,
                decoration: BoxDecoration(
                  color: accent.color,
                  borderRadius: BorderRadius.circular(16 * u),
                ),
              ),
              SizedBox(height: 24 * u),
              // Cartes de contact séparées, comme sur la page.
              for (var i = 0; i < 3; i++)
                Container(
                  height: 60 * u,
                  margin: EdgeInsets.only(bottom: 8 * u),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(16 * u),
                    border: Border.all(color: p.line, width: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on PublicCardThumbnail {
  /// Bento, Éditorial : le contenu en haut, le bouton en bas par-dessus,
  /// comme sur le site où il reste fixé en bas de l'écran.
  Widget _next(double pad, double inner) {
    final p = PublicNextPalette.of(settings.theme);
    final u = inner / PublicCardNextView.contentWidth(settings.layout);

    return Container(
      width: width,
      height: height,
      color: p.background,
      padding: EdgeInsets.all(pad),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: double.infinity,
                child: PublicCardNextView(
                  width: inner,
                  settings: settings,
                  accent: accent,
                  withContacts: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PublicCardNextSaveButton(
              unit: u,
              settings: settings,
              accent: accent,
              labelled: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloc « Aperçu en direct » : le haut de la page publique telle qu'elle
/// est en ligne, avec les vraies infos, puis son bouton « Enregistrer le
/// contact ». Change avec la disposition, le thème, le style et la couleur.
class PublicCardLivePreview extends StatelessWidget {
  const PublicCardLivePreview({
    super.key,
    required this.settings,
    required this.accent,
    required this.identity,
    this.contacts = const [],
  });

  final PublicCardSettings settings;
  final EffectiveAccent accent;
  final PreviewIdentity identity;

  /// Contacts visibles sur la page parmi `phone` et `whatsapp`, dans leur
  /// ordre : les tuiles du bento. Les autres dispositions n'en font rien.
  final List<String> contacts;

  @override
  Widget build(BuildContext context) {
    final p = PublicPagePalette.of(settings.theme);
    final isNext = PublicCardSettings.nextLayouts.contains(settings.layout);

    return Container(
      key: const Key('public-card-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Le cadre s'arrête juste sous le bouton, où qu'il soit posé.
          if (isNext) {
            // Bento, Éditorial : le haut de la page, puis leur bouton en
            // pilule (fixé en bas de l'écran sur le site).
            final u = constraints.maxWidth /
                PublicCardNextView.contentWidth(settings.layout);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aperçu en direct',
                  style: TextStyle(fontFamily: 'Archivo', fontSize: 12, color: p.muted),
                ),
                const SizedBox(height: 12),
                PublicCardNextView(
                  width: constraints.maxWidth,
                  settings: settings,
                  accent: accent,
                  identity: identity,
                  contacts: contacts,
                ),
                SizedBox(height: 20 * u),
                PublicCardNextSaveButton(
                  key: const Key('preview-save-button'),
                  unit: u,
                  settings: settings,
                  accent: accent,
                ),
              ],
            );
          }
          final u = constraints.maxWidth / 358;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aperçu en direct',
                style: TextStyle(fontFamily: 'Archivo', fontSize: 12, color: p.muted),
              ),
              const SizedBox(height: 12),
              PublicCardHero(
                width: constraints.maxWidth,
                settings: settings,
                accent: accent,
                identity: identity,
              ),
              SizedBox(height: 20 * u),
              Container(
                key: const Key('preview-save-button'),
                height: 56 * u,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.color,
                  borderRadius: BorderRadius.circular(16 * u),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12 * u),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined, size: 20 * u, color: accent.onColor),
                    SizedBox(width: 10 * u),
                    // Réduit plutôt que de déborder sur un écran étroit.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Enregistrer le contact',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.w700,
                            fontSize: 16 * u,
                            color: accent.onColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

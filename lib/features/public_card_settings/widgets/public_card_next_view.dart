import 'package:flutter/material.dart';

import '../models/public_card_settings.dart';
import '../public_card_styles.dart';
import 'public_card_thumbnail.dart' show PreviewIdentity;

/// Page publique en disposition Bento ou Éditorial, dessinée d'après le
/// site en ligne (LayoutBento / LayoutEditorial et leurs blocs,
/// publicCardNext/, main 83cad2d), telle qu'elle s'affiche sur téléphone.
/// Toutes les tailles sont celles du site, multipliées par [width] /
/// largeur du contenu de la disposition (350 px en bento, 346 px en
/// éditorial).
///
/// Avec [identity] : vrais textes (aperçu en direct). Sans : traits
/// (vignettes du carrousel). [withContacts] dessine la page en petit pour
/// les vignettes : tuiles ou lignes de contact, « Partager » du bento.
/// [contacts] : tuiles du bento dans l'aperçu (`phone`, `whatsapp`), dans
/// l'ordre de la page.
///
/// Le bouton « Enregistrer le contact », fixé en bas de l'écran sur le
/// site, est dessiné à part : [PublicCardNextSaveButton].
class PublicCardNextView extends StatelessWidget {
  const PublicCardNextView({
    super.key,
    required this.width,
    required this.settings,
    required this.accent,
    this.identity,
    this.withContacts = false,
    this.contacts = const [],
  });

  final double width;
  final PublicCardSettings settings;
  final EffectiveAccent accent;
  final PreviewIdentity? identity;
  final bool withContacts;
  final List<String> contacts;

  /// Largeur du contenu sur le site : colonne de 390 px moins les marges
  /// de la disposition.
  static double contentWidth(String layout) =>
      layout == 'editorial' ? 346 : 350;

  bool get _editorial => settings.layout == 'editorial';

  double get _u => width / contentWidth(settings.layout);

  /// Au-delà de 22 caractères, le site réduit le nom.
  bool get _nameIsLong => (identity?.fullName.length ?? 0) > 22;

  @override
  Widget build(BuildContext context) {
    final p = PublicNextPalette.of(settings.theme);
    return SizedBox(
        width: width, child: _editorial ? _editorialPage(p) : _bentoPage(p));
  }

  TextStyle _archivo(double size, Color color,
          {FontWeight weight = FontWeight.w400, double? height}) =>
      TextStyle(
        fontFamily: 'Archivo',
        fontSize: size * _u,
        fontWeight: weight,
        color: color,
        height: height,
      );

  TextStyle _syne(double size, Color color,
          {FontWeight weight = FontWeight.w700,
          double? height,
          double spacing = 0}) =>
      TextStyle(
        fontFamily: 'Syne',
        fontSize: size * _u,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: spacing * size * _u,
      );

  Widget _bar(double w, double h, Color color) => Container(
        width: w * _u,
        height: h * _u,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(h * _u / 2),
        ),
      );

  /// « KART » de l'en-tête (Syne 800, interlettrage 0,18 em).
  Widget _wordmark(double size, Color color) => identity == null
      ? _bar(54, size * 0.6, color)
      : Text('KART',
          style: _syne(size, color, weight: FontWeight.w800, spacing: 0.18));

  /// Photo absente : initiales sur le bleu nuit du site.
  Widget _avatar(double size, double radius, double fontSize) => Container(
        width: size * _u,
        height: size * _u,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PublicCardStyles.initialsBackground,
          borderRadius: BorderRadius.circular(radius * _u),
        ),
        child: identity == null
            ? null
            : Text(identity!.initials,
                style: _syne(fontSize, Colors.white, weight: FontWeight.w800)),
      );

  /// Tuile de logo : logo entier sur fond clair, marge intérieure de 5 px.
  Widget _logoTile(Widget logo, double size, double radius, Color background,
          Color border) =>
      Container(
        width: size * _u,
        height: size * _u,
        padding: EdgeInsets.all(5 * _u),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius * _u),
          border: Border.all(color: border),
        ),
        child: FittedBox(child: logo),
      );

  BoxDecoration _tile(PublicNextPalette p, double radius, {Color? color}) =>
      BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius * _u),
        border: Border.all(color: color ?? p.line),
      );

  // ── Bento ────────────────────────────────────────────────────────────
  // En-tête « KART » / « Carte digitale », tuile d'identité, Appeler et
  // WhatsApp en tuiles carrées. Vignette : puis « Partager » en pleine
  // largeur, sans tuile QR (sur téléphone, le site la retire).
  Widget _bentoPage(PublicNextPalette p) {
    final id = identity;
    final ink = p.accentInk(accent.color);
    final gap = SizedBox(height: 12 * _u);

    Widget square(
            {required Color? fill,
            required Color mark,
            required Color lines}) =>
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: EdgeInsets.all(18 * _u),
              decoration: _tile(p, 22, color: fill),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 28 * _u,
                    height: 28 * _u,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: mark, width: 1.2),
                    ),
                  ),
                  _bar(84, 12, lines),
                ],
              ),
            ),
          ),
        );

    // Tuile de contact de l'aperçu. Appeler : pleine, de la couleur
    // d'accent, numéro dessous. WhatsApp : icône verte. Une tuile sans
    // voisine prend toute la largeur, à la hauteur prévue par le site.
    final contactTiles =
        contacts.where((key) => key == 'phone' || key == 'whatsapp').toList();
    Widget contactTile(String key, {required bool wide}) {
      final isPhone = key == 'phone';
      final foreground = isPhone ? accent.onColor : p.text;
      return Container(
        key: Key('bento-$key'),
        constraints: BoxConstraints(minHeight: wide ? 132 * _u : 0),
        padding: EdgeInsets.all(18 * _u),
        decoration: _tile(p, 22, color: isPhone ? accent.color : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              isPhone
                  ? Icons.phone_outlined
                  : Icons.chat_bubble_outline,
              size: 28 * _u,
              color: isPhone ? foreground : p.whatsapp,
            ),
            SizedBox(height: 18 * _u),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPhone ? 'Appeler' : 'WhatsApp',
                    maxLines: 1, style: _syne(18, foreground)),
                SizedBox(height: 2 * _u),
                Text(
                  isPhone ? (id?.phone ?? '') : 'Écrire un message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _archivo(12,
                      isPhone ? foreground.withValues(alpha: 0.75) : p.muted),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 6 * _u),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _wordmark(15, p.text),
              id == null
                  ? _bar(70, 7, p.faint)
                  : Text('Carte digitale', style: _archivo(12, p.faint)),
            ],
          ),
        ),
        gap,
        Container(
          padding: EdgeInsets.all(22 * _u),
          decoration: _tile(p, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Le logo ; à défaut, la photo (ici : les initiales).
              id?.logo != null
                  ? _logoTile(id!.logo!, 64, 18, const Color(0xFFF6F3EC),
                      Colors.transparent)
                  : _avatar(64, 18, 22),
              SizedBox(height: 14 * _u),
              if (id == null) ...[
                _bar(170, 21, p.strong),
                SizedBox(height: 10 * _u),
                _bar(120, 9, ink),
                SizedBox(height: 8 * _u),
                _bar(150, 9, p.soft),
              ] else ...[
                Text(id.fullName,
                    style: _syne(_nameIsLong ? 22 : 30, p.strong, height: 1.1)),
                if (id.jobTitle.isNotEmpty) ...[
                  SizedBox(height: 6 * _u),
                  Text(id.jobTitle,
                      style: _archivo(15, ink, weight: FontWeight.w600)),
                ],
                if (id.company.isNotEmpty) ...[
                  SizedBox(height: 6 * _u),
                  Text(id.company, style: _archivo(14, p.soft)),
                ],
              ],
            ],
          ),
        ),
        // Aperçu : les tuiles Appeler et WhatsApp visibles sur la carte ;
        // rien si aucune des deux ne l'est.
        if (!withContacts && contactTiles.isNotEmpty) ...[
          gap,
          if (contactTiles.length == 1)
            contactTile(contactTiles.single, wide: true)
          else
            Row(
              children: [
                Expanded(
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: contactTile(contactTiles[0], wide: false))),
                SizedBox(width: 12 * _u),
                Expanded(
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: contactTile(contactTiles[1], wide: false))),
              ],
            ),
        ],
        if (withContacts) ...[
          gap,
          Row(
            children: [
              // Appeler : tuile pleine de la couleur d'accent.
              square(
                  fill: accent.color,
                  mark: accent.onColor,
                  lines: accent.onColor),
              SizedBox(width: 12 * _u),
              // WhatsApp : icône verte.
              square(fill: null, mark: p.whatsapp, lines: p.text),
            ],
          ),
          gap,
          // « Partager » : seule sur sa ligne, toute la largeur.
          Container(
            key: const Key('bento-share'),
            constraints: BoxConstraints(minHeight: 132 * _u),
            padding: EdgeInsets.all(18 * _u),
            decoration: _tile(p, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.share_outlined, size: 26 * _u, color: p.text),
                SizedBox(height: 18 * _u),
                if (id == null)
                  _bar(84, 12, p.text)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Partager', style: _syne(17, p.text)),
                      SizedBox(height: 2 * _u),
                      Text('Lien ou QR', style: _archivo(12, p.muted)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Éditorial ────────────────────────────────────────────────────────
  // En-tête « KART » / bouton rond « Partager », photo ronde et logo, nom
  // en très grand sur deux lignes, « poste chez entreprise », filet de la
  // couleur d'accent, [une ligne par contact, la première en plein].
  Widget _editorialPage(PublicNextPalette p) {
    final id = identity;
    final ink = p.accentInk(accent.color);

    // Prénom sur une ligne, le reste sur la suivante.
    final parts = (id?.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((v) => v.isNotEmpty)
        .toList();
    final nameLines = parts.length > 1
        ? [parts.first, parts.skip(1).join(' ')]
        : [parts.join()];
    final nameStyle = _nameIsLong
        ? _syne(30, p.text,
            weight: FontWeight.w800, height: 1.08, spacing: -0.01)
        : _syne(44, p.text, weight: FontWeight.w800, height: 1, spacing: -0.01);

    Widget row({required bool primary}) => Container(
          height: 60 * _u,
          margin: EdgeInsets.only(top: (primary ? 0 : 10) * _u),
          padding: EdgeInsets.symmetric(horizontal: 18 * _u),
          alignment: Alignment.centerLeft,
          decoration: _tile(p, 16, color: primary ? p.inverseBackground : null),
          child: _bar(primary ? 110 : 90, 10, primary ? p.inverseText : p.text),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _wordmark(14, p.text),
            Container(
              width: 44 * _u,
              height: 44 * _u,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.surface,
                shape: BoxShape.circle,
                border: Border.all(color: p.shareLine),
              ),
              child: Icon(Icons.share_outlined, size: 19 * _u, color: p.text),
            ),
          ],
        ),
        SizedBox(height: (26 + 18) * _u),
        Row(
          children: [
            _avatar(56, 28, 18),
            if (id?.logo != null) ...[
              SizedBox(width: 12 * _u),
              _logoTile(id!.logo!, 56, 16, Colors.white, p.logoLine),
            ],
          ],
        ),
        SizedBox(height: 16 * _u),
        if (id == null) ...[
          _bar(150, 30, p.text),
          SizedBox(height: 10 * _u),
          _bar(200, 30, p.text),
          SizedBox(height: 16 * _u),
          _bar(210, 10, p.soft),
        ] else ...[
          for (final line in nameLines) Text(line, style: nameStyle),
          if (id.jobTitle.isNotEmpty || id.company.isNotEmpty) ...[
            SizedBox(height: 16 * _u),
            Text.rich(
              TextSpan(
                style: _archivo(16, p.soft, height: 1.45),
                children: [
                  if (id.jobTitle.isNotEmpty) TextSpan(text: id.jobTitle),
                  if (id.jobTitle.isNotEmpty && id.company.isNotEmpty)
                    const TextSpan(text: ' chez '),
                  if (id.company.isNotEmpty)
                    TextSpan(
                      text: id.company,
                      style:
                          TextStyle(color: p.text, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ],
        ],
        SizedBox(height: 16 * _u),
        Container(
          key: const Key('editorial-rule'),
          width: 48 * _u,
          height: 3 * _u,
          decoration: BoxDecoration(
              color: ink, borderRadius: BorderRadius.circular(2 * _u)),
        ),
        if (withContacts) ...[
          SizedBox(height: 26 * _u),
          row(primary: true),
          row(primary: false),
          row(primary: false),
        ],
      ],
    );
  }
}

/// « Enregistrer le contact » des dispositions Bento et Éditorial : pilule
/// de 56 px avec ombre, fixée en bas de l'écran sur le site. Bento : fond
/// « inversé » (clair sur page sombre) ; Éditorial : couleur d'accent.
///
/// Avec [labelled] : icône et texte (aperçu). Sans : pilule seule (vignette).
class PublicCardNextSaveButton extends StatelessWidget {
  const PublicCardNextSaveButton({
    super.key,
    required this.unit,
    required this.settings,
    required this.accent,
    this.labelled = true,
  });

  /// Pixels de l'app pour 1 px du site.
  final double unit;
  final PublicCardSettings settings;
  final EffectiveAccent accent;
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final p = PublicNextPalette.of(settings.theme);
    final inverse = settings.layout == 'bento';
    final background = inverse ? p.inverseBackground : accent.color;
    final foreground = inverse ? p.inverseText : accent.onColor;
    final shadow = p.stickyShadow;

    return Container(
      height: 56 * unit,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 16 * unit),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: shadow.color,
            offset: shadow.offset * unit,
            blurRadius: shadow.blurRadius * unit,
          ),
        ],
      ),
      child: !labelled
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1_outlined,
                    size: 20 * unit, color: foreground),
                SizedBox(width: 10 * unit),
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
                        fontSize: 16 * unit,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

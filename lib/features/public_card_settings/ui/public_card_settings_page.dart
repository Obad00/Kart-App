import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/kart_tokens.dart';
import '../data/public_card_settings_service.dart';
import '../models/public_card_settings.dart';
import '../providers/public_card_settings_provider.dart';
import '../public_card_styles.dart';
import '../widgets/public_card_thumbnail.dart';

/// Écran « Ma carte publique » (maquette 01) : présentation de la page
/// `kart.business/card/{slug}` — disposition, thème, couleur d'accent,
/// style de carte, ordre et visibilité des sections — avec un aperçu en
/// direct. Rien n'est envoyé avant « Enregistrer ».
///
/// Titres en Syne, texte courant en Archivo, comme la maquette.
class PublicCardSettingsPage extends StatelessWidget {
  const PublicCardSettingsPage({
    super.key,
    this.service = const PublicCardSettingsService(),
    this.identity = const PreviewIdentity(fullName: ''),
    this.fallbackActivatedFields = const [],
    this.onOpenUrl,
    this.onEditInfo,
    this.onEditLogo,
    this.onPickColor,
    this.onSaved,
  });

  final PublicCardSettingsService service;

  /// Infos de la carte écrites dans l'aperçu.
  final PreviewIdentity identity;

  /// `activated_fields` de la carte déjà chargée, si l'API ne les renvoie
  /// pas avec les réglages.
  final List<String> fallbackActivatedFields;

  /// « Voir ↗ » : ouvre la page publique avec les réglages en cours.
  final Future<void> Function(Uri url)? onOpenUrl;

  /// « Modifier mes infos → » : ouvre le formulaire existant.
  final Future<void> Function(BuildContext context)? onEditInfo;

  /// « Changer le logo → » : ouvre la feuille « Couleur et logo ».
  final Future<void> Function(BuildContext context)? onEditLogo;

  /// « + » : ouvre le sélecteur de couleur ; renvoie la couleur choisie.
  final Future<Color?> Function(BuildContext context, Color current)?
      onPickColor;

  /// Appelé après un enregistrement réussi (l'écran Carte se met à jour).
  final VoidCallback? onSaved;

  /// Adresse de la page publique avec les réglages EN COURS, enregistrés
  /// ou non : le site les applique à l'affichage seulement.
  static Uri previewUrl(String slug, PublicCardSettings settings) => Uri.https(
        'kart.business',
        '/card/$slug',
        {
          'layout': settings.layout,
          'theme': settings.theme,
          'style': settings.cardStyle,
        },
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PublicCardSettingsProvider(
        service: service,
        fallbackActivatedFields: fallbackActivatedFields,
      )..load(),
      child: _SettingsView(page: this),
    );
  }
}

/// Couleurs de l'écran. Sombre : valeurs de la maquette 01. Clair : absent
/// de la maquette, dérivé des couleurs de l'app (KartTokens).
class _Ui {
  const _Ui({
    required this.background,
    required this.line,
    required this.strong,
    required this.text,
    required this.soft,
    required this.muted,
    required this.listBackground,
    required this.handle,
    required this.switchOn,
    required this.switchOff,
    required this.switchOffThumb,
    required this.primary,
    required this.onPrimary,
  });

  factory _Ui.of(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const _Ui(
        background: Color(0xFF1A1A1A),
        line: Color(0xFF2A2A2D),
        strong: Color(0xFFFFFFFF),
        text: Color(0xFFE9E6DF),
        soft: Color(0xFFA8A59E),
        muted: Color(0xFF8C8A85),
        listBackground: Color(0xFF222224),
        handle: Color(0xFF5A5A5E),
        switchOn: Color(0xFF4ADE80),
        switchOff: Color(0xFF3A3A3E),
        switchOffThumb: Color(0xFFA8A59E),
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF0B0B0C),
      );
    }
    final t = KartTokens.of(context);
    return _Ui(
      background: t.pageBackground,
      line: t.buttonStroke,
      strong: t.textPrimary,
      text: t.textPrimary,
      soft: t.textSecondary,
      muted: t.textSecondary,
      listBackground: t.softFill,
      handle: t.textSecondary.withValues(alpha: 0.6),
      switchOn: t.positive,
      switchOff: t.softBorder,
      switchOffThumb: Colors.white,
      primary: t.textPrimary,
      onPrimary: t.pageBackground,
    );
  }

  final Color background;
  final Color line;
  final Color strong;
  final Color text;
  final Color soft;
  final Color muted;
  final Color listBackground;
  final Color handle;
  final Color switchOn;
  final Color switchOff;
  final Color switchOffThumb;

  /// Bouton principal (« Enregistrer ») et contour de l'élément choisi.
  final Color primary;
  final Color onPrimary;

  TextStyle body(double size, Color color, {FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: 'Archivo', fontSize: size, color: color, fontWeight: weight, height: 1.25);

  TextStyle title(double size) => TextStyle(
      fontFamily: 'Syne', fontSize: size, color: strong, fontWeight: FontWeight.w700, height: 1.2);
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.page});

  final PublicCardSettingsPage page;

  Future<void> _save(BuildContext context) async {
    final provider = context.read<PublicCardSettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.save();
    if (error == null) page.onSaved?.call();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error ?? 'Carte publique mise à jour.'),
      ));
  }

  /// Quitter avec des changements non enregistrés : on demande d'abord.
  Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter sans enregistrer ?'),
        content: const Text('Vos changements ne seront pas appliqués.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final provider = context.watch<PublicCardSettingsProvider>();

    return PopScope(
      canPop: !provider.hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave(context)) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: ui.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TopBar(
                  onSee: !provider.isReady ||
                          page.onOpenUrl == null ||
                          provider.slug.isEmpty
                      ? null
                      : () => page.onOpenUrl!(PublicCardSettingsPage.previewUrl(
                          provider.slug, provider.settings)),
                ),
              ),
              Expanded(
                child: !provider.isReady
                    ? _LoadState(provider: provider)
                    : _Content(page: page),
              ),
              if (provider.isReady) _BottomBar(onSave: () => _save(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre du haut : retour, titre, « Voir ↗ ».
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSee});

  final VoidCallback? onSee;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Retour',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ui.line),
                ),
                child: Icon(Icons.chevron_left_rounded, size: 24, color: ui.text),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Sur un petit écran, le titre est réduit plutôt que coupé.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Ma carte publique', maxLines: 1, style: ui.title(18)),
            ),
          ),
          const SizedBox(width: 8),
          // Zone de 44 px de haut autour du texte.
          InkWell(
            key: const Key('see-public-page'),
            borderRadius: BorderRadius.circular(10),
            onTap: onSee,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // « Voir ↗ » : la flèche est une icône, Archivo n'ayant
                  // pas ce caractère.
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Voir', style: ui.body(14, ui.soft)),
                      const SizedBox(width: 3),
                      Icon(Icons.north_east_rounded, size: 14, color: ui.soft),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chargement en cours, ou erreur réseau avec « Réessayer ».
class _LoadState extends StatelessWidget {
  const _LoadState({required this.provider});

  final PublicCardSettingsProvider provider;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    if (provider.error == null) {
      return Center(child: CircularProgressIndicator(color: ui.soft));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 40, color: ui.soft),
            const SizedBox(height: 16),
            Text(provider.error!, textAlign: TextAlign.center, style: ui.body(15, ui.text)),
            const SizedBox(height: 20),
            _OutlineButton(
              label: 'Réessayer',
              onTap: provider.loading ? null : provider.load,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.page});

  final PublicCardSettingsPage page;

  static const _layoutLabels = {
    'physical': 'Carte physique',
    'classic': 'Classique',
    'banner': 'Bandeau',
  };

  /// Largeur des vignettes (96 px, 10 px d'écart) contre la largeur utile.
  static bool _carouselOverflows(BuildContext context) {
    final count = PublicCardSettings.layouts.length;
    return count * 96 + (count - 1) * 10 > MediaQuery.sizeOf(context).width - 32;
  }

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final provider = context.watch<PublicCardSettingsProvider>();
    final settings = provider.settings;
    final accent = provider.accent;

    Widget section(String title, List<Widget> children, {String? hint}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(title, style: ui.title(15))),
                if (hint != null) Text(hint, style: ui.body(12, ui.muted)),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        );

    Widget link(String label, Key key, VoidCallback? onTap) => Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            key: key,
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: ui.body(14, ui.text, weight: FontWeight.w600)),
              ),
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      children: [
        PublicCardLivePreview(
          settings: settings,
          accent: accent,
          identity: page.identity,
        ),
        const SizedBox(height: 22),

        // ── Disposition ────────────────────────────────────────────────
        // « Faire défiler → » seulement si toutes les vignettes ne tiennent
        // pas à l'écran.
        section('Disposition', hint: _carouselOverflows(context) ? 'Faire défiler →' : null, [
          SizedBox(
            height: 150 + 6 + 16,
            // Déborde à droite jusqu'au bord de l'écran, comme la maquette.
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: MediaQuery.sizeOf(context).width - 16,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: PublicCardSettings.layouts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final layout = PublicCardSettings.layouts[index];
                  final selected = layout == settings.layout;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Disposition ${_layoutLabels[layout]}',
                    child: GestureDetector(
                      key: Key('layout-$layout'),
                      onTap: () => provider.setLayout(layout),
                      child: SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Choisie : contour de 2 px ; sinon 1 px.
                            Container(
                              width: 96,
                              height: 150,
                              foregroundDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? ui.primary : ui.line,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PublicCardThumbnail(
                                  settings: settings.copyWith(layout: layout),
                                  accent: accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _layoutLabels[layout]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ui.body(
                                12,
                                selected ? ui.text : ui.soft,
                                weight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Les mêmes infos, la même couleur : seule la mise en page change.',
              style: ui.body(12, ui.muted)),
        ]),
        const SizedBox(height: 22),

        // ── Thème de la page ───────────────────────────────────────────
        section('Thème de la page', [
          Row(
            children: [
              for (final theme in PublicCardSettings.themes) ...[
                if (theme != PublicCardSettings.themes.first) const SizedBox(width: 10),
                Expanded(
                  child: _ThemeChoice(
                    theme: theme,
                    selected: theme == settings.theme,
                    onTap: () => provider.setTheme(theme),
                  ),
                ),
              ],
            ],
          ),
        ]),
        const SizedBox(height: 22),

        // ── Couleur d'accent ───────────────────────────────────────────
        section("Couleur d'accent", [
          _AccentPicker(page: page),
        ]),
        const SizedBox(height: 22),

        // ── Style de la carte (carte physique seulement) ───────────────
        if (settings.layout == 'physical') ...[
          section('Style de la carte', [
            Row(
              children: [
                for (final style in PublicCardSettings.cardStyles) ...[
                  if (style != PublicCardSettings.cardStyles.first) const SizedBox(width: 10),
                  Expanded(
                    child: _StyleChoice(
                      style: style,
                      accent: accent.color,
                      selected: style == settings.cardStyle,
                      onTap: () => provider.setCardStyle(style),
                    ),
                  ),
                ],
              ],
            ),
          ]),
          const SizedBox(height: 22),
        ],

        // ── Ce qui est visible ─────────────────────────────────────────
        section('Ce qui est visible', hint: 'Glisser pour réordonner', [
          const _SectionList(),
          const SizedBox(height: 10),
          Text("Un champ vide n'apparaît jamais, même activé.", style: ui.body(12, ui.muted)),
          if (page.onEditInfo != null)
            link('Modifier mes infos →', const Key('edit-info'), () => page.onEditInfo!(context)),
        ]),
      ],
    );
  }
}

/// « Sombre » / « Clair » : chaque bouton montre le fond du thème.
class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({required this.theme, required this.selected, required this.onTap});

  final String theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final palette = PublicPagePalette.of(theme);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        key: Key('theme-$theme'),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? ui.primary : ui.line, width: selected ? 2 : 1),
          ),
          child: Text(
            theme == 'light' ? 'Clair' : 'Sombre',
            style: ui.body(14, palette.text, weight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Vignette d'un style de carte : le vrai dégradé (public_card_styles).
class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    required this.style,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String style;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {'mat': 'Mat', 'gradient': 'Dégradé', 'marine': 'Marine'};

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Style ${_labels[style]}',
      child: GestureDetector(
        key: Key('style-$style'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                gradient: PublicCardStyles.cardLook(style, accent).gradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? ui.primary : ui.line,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(_labels[style]!, style: ui.body(12, selected ? ui.text : ui.soft)),
          ],
        ),
      ),
    );
  }
}

/// Pastilles de couleur, « + » et lien vers le logo. Modifie la couleur
/// d'accent de la carte (`accent_color`). Verrouillé si l'entreprise impose
/// la sienne.
class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.page});

  final PublicCardSettingsPage page;

  /// Trop sombre pour se voir sur la carte noire : on l'éclaircit.
  static const _cardBlack = Color(0xFF0E0E10);

  Future<void> _pickCustom(BuildContext context) async {
    final provider = context.read<PublicCardSettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await page.onPickColor!(context, provider.accent.color);
    if (picked == null) return;

    // Une couleur peu lisible est ajustée : même teinte, éclaircie jusqu'à
    // se détacher de la carte.
    final adjusted = PublicCardStyles.readableAccent(picked, const [_cardBlack], minimum: 3);
    provider.setAccent(adjusted);
    if (adjusted != picked) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Couleur éclaircie pour rester lisible sur la carte.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final provider = context.watch<PublicCardSettingsProvider>();
    final current = provider.accent.color;
    final locked = provider.accentLocked;
    final isPreset = PublicCardStyles.accentPresets.any((c) => c.toARGB32() == current.toARGB32());

    Widget ring({required bool selected, required Widget child}) => Container(
          // Choisie : anneau de la couleur du fond (3 px) puis anneau blanc
          // (2 px), comme la maquette.
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? ui.primary : Colors.transparent, width: 2),
          ),
          child: child,
        );

    final swatches = Wrap(
      spacing: 2,
      runSpacing: 2,
      children: [
        for (final color in PublicCardStyles.accentPresets)
          Semantics(
            button: true,
            selected: color.toARGB32() == current.toARGB32(),
            label: 'Couleur ${PublicCardStyles.toHex(color)}',
            child: GestureDetector(
              key: Key('accent-${PublicCardStyles.toHex(color)}'),
              onTap: locked ? null : () => provider.setAccent(color),
              child: ring(
                selected: !locked && color.toARGB32() == current.toARGB32(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        // « + » : couleur libre. Affiche la couleur choisie si elle n'est
        // pas une des pastilles.
        Semantics(
          button: true,
          label: 'Choisir une autre couleur',
          child: GestureDetector(
            key: const Key('accent-custom'),
            onTap: locked || page.onPickColor == null ? null : () => _pickCustom(context),
            child: ring(
              selected: !locked && !isPreset,
              child: CustomPaint(
                painter: isPreset || locked ? _DashedCircle(ui.handle) : null,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isPreset || locked ? null : current,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '+',
                    style: ui.body(18, isPreset || locked ? ui.soft : PublicCardStyles.onColor(current)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (locked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grisées et inactives : la couleur vient de l'entreprise.
          IgnorePointer(child: Opacity(opacity: 0.35, child: swatches)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                key: const Key('accent-locked'),
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: current, shape: BoxShape.circle),
                child: Icon(Icons.lock_outline_rounded, size: 15, color: PublicCardStyles.onColor(current)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Couleur définie par votre entreprise',
                    style: ui.body(14, ui.text, weight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        swatches,
        const SizedBox(height: 10),
        Text('« + » ouvre un sélecteur ; une couleur peu lisible est refusée ou ajustée.',
            style: ui.body(12, ui.muted)),
        if (page.onEditLogo != null)
          InkWell(
            key: const Key('edit-logo'),
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              await page.onEditLogo!(context);
              // La feuille peut aussi changer la couleur : on la relit.
              await provider.refreshAccent();
            },
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Changer le logo →', style: ui.body(14, ui.text, weight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Contour en pointillés de la pastille « + ».
class _DashedCircle extends CustomPainter {
  const _DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const dashes = 28;
    const sweep = 2 * 3.141592653589793 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.5), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color;
}

/// Interrupteur de la maquette : 44 × 26, pastille de 20.
class _Toggle extends StatelessWidget {
  const _Toggle({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        // Zone de toucher de 54 × 54 autour du dessin de 44 × 26.
        child: SizedBox(
          width: 54,
          height: 54,
          child: Center(
            child: Opacity(
              opacity: onChanged == null ? 0.5 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? ui.switchOn : ui.switchOff,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: value ? Colors.white : ui.switchOffThumb,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sections de la page, réordonnables, chacune avec son interrupteur.
class _SectionList extends StatelessWidget {
  const _SectionList();

  static const _labels = {
    'bio': 'Bio',
    'phone': 'Téléphone mobile',
    'whatsapp': 'WhatsApp',
    'email': 'Email',
    'website': 'Site web',
    'socials': 'Réseaux sociaux',
    'company': 'Entreprise',
    'skills': 'Compétences',
    'experiences': 'Expériences',
    'educations': 'Formations',
    'interests': "Centres d'intérêt",
  };

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final provider = context.watch<PublicCardSettingsProvider>();
    final order = provider.settings.order;
    final phoneVisible = provider.isVisible('phone');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ui.listBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ui.line),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: order.length,
        onReorder: provider.reorder,
        proxyDecorator: (child, _, __) => Material(color: ui.listBackground, child: child),
        itemBuilder: (context, index) {
          final section = order[index];
          // WhatsApp est fabriqué depuis le téléphone : sans lui, rien à
          // afficher, l'interrupteur est grisé.
          final dependsOnPhone = section == 'whatsapp' && !phoneVisible;
          final visible = provider.isVisible(section) && !dependsOnPhone;

          return Container(
            key: ValueKey(section),
            height: 54,
            padding: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              border: index == order.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: ui.line)),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Semantics(
                    label: 'Déplacer ${_labels[section]}',
                    // Poignée : zone de 44 px de large, toute la hauteur.
                    child: Container(
                      width: 44,
                      height: 54,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Icon(Icons.drag_indicator_rounded, size: 20, color: ui.handle),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[section]!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ui.body(14, visible ? ui.text : ui.muted),
                      ),
                      if (dependsOnPhone)
                        Text("Activez d'abord le téléphone", style: ui.body(11, ui.muted)),
                    ],
                  ),
                ),
                _Toggle(
                  key: Key('switch-$section'),
                  value: visible,
                  onChanged: dependsOnPhone ? null : (value) => provider.setVisible(section, value),
                ),
                const SizedBox(width: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({super.key, required this.label, required this.onTap, this.width});

  final String label;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: width,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ui.line),
          ),
          child: Text(label, maxLines: 1, style: ui.body(15, ui.text)),
        ),
      ),
    );
  }
}

/// « Réinitialiser » (1/3) et « Enregistrer » (2/3), fixés en bas.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final ui = _Ui.of(context);
    final provider = context.watch<PublicCardSettingsProvider>();
    final busy = provider.saving;
    final canSave = !busy && provider.hasChanges;

    return Container(
      color: ui.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: _OutlineButton(
              key: const Key('reset'),
              label: 'Réinitialiser',
              onTap: busy || provider.settings == const PublicCardSettings()
                  ? null
                  : provider.resetToDefaults,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Semantics(
              button: true,
              enabled: canSave,
              child: Opacity(
                opacity: canSave || busy ? 1 : 0.45,
                child: InkWell(
                  key: const Key('save'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: canSave ? onSave : null,
                  child: Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ui.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: busy
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ui.onPrimary),
                          )
                        : Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: ui.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

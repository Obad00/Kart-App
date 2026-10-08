// Écran « Ma carte publique » : chargement, erreur réseau, aperçu en
// direct, cinq dispositions, couleur d'accent (pastilles, « + », verrou
// entreprise), enregistrement (présentation, visibilité, couleur) et
// lien « Voir ↗ ».
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:provider/provider.dart';
import 'package:kart_app/features/public_card_settings/data/public_card_settings_service.dart';
import 'package:kart_app/features/public_card_settings/models/public_card_settings.dart';
import 'package:kart_app/features/public_card_settings/public_card_styles.dart';
import 'package:kart_app/features/public_card_settings/ui/public_card_settings_page.dart';
import 'package:kart_app/features/public_card_settings/widgets/public_card_thumbnail.dart';
import 'package:kart_app/shared/widgets/app_loader.dart';
import 'package:kart_app/shared/widgets/auth_outline_button.dart';
import 'package:kart_app/shared/widgets/auth_primary_button.dart';
import 'package:kart_app/shared/widgets/glass_app_bar.dart';
import 'package:kart_app/shared/widgets/glass_dialog.dart';

const _gold = Color(0xFFC99A2E);
const _blue = Color(0xFF4F8EF7);
const _navy = Color(0xFF0B2B5B);

/// Faux serveur : renvoie les réglages donnés, enregistre les appels reçus.
class _FakeService extends PublicCardSettingsService {
  _FakeService({
    this.settings = const PublicCardSettings(),
    this.accent = EffectiveAccent.fallback,
    this.activatedFields = const ['phone', 'email'],
  });

  PublicCardSettings settings;
  EffectiveAccent accent;
  List<String>? activatedFields;

  bool fetchFails = false;
  bool saveFails = false;
  final List<String> calls = [];
  PublicCardSettings? savedSettings;
  List<String>? savedFields;
  String? savedAccent;

  PublicCardSettingsData get _data => PublicCardSettingsData(
        slug: 'awa-diop',
        settings: settings,
        accent: accent,
        activatedFields: activatedFields,
      );

  @override
  Future<PublicCardSettingsData> fetch() async {
    calls.add('fetch');
    if (fetchFails) throw Exception('réseau');
    return _data;
  }

  @override
  Future<PublicCardSettingsData> save(PublicCardSettings settings) async {
    calls.add('save');
    if (saveFails) throw Exception('réseau');
    savedSettings = this.settings = settings;
    return _data;
  }

  @override
  Future<void> saveCard({List<String>? activatedFields, String? accentHex}) async {
    calls.add('card');
    if (saveFails) throw Exception('réseau');
    if (activatedFields != null) {
      savedFields = this.activatedFields = activatedFields;
    }
    if (accentHex != null) {
      savedAccent = accentHex;
      final color = EffectiveAccent.parseHex(accentHex)!;
      accent = EffectiveAccent(
          color: color, onColor: PublicCardStyles.onColor(color));
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeService service, {
  ThemeData? theme,
  Size size = const Size(390, 2600),
  Future<void> Function(Uri)? onOpenUrl,
  Future<void> Function(BuildContext)? onEditLogo,
  Future<Color?> Function(BuildContext, Color)? onPickColor,
  VoidCallback? onSaved,
}) async {
  // Par défaut, assez haut pour que tout l'écran soit construit d'un coup.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // CardProvider : le loader partagé de l'app y lit la couleur du compte.
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => CardProvider(),
    child: _app(theme, service, onOpenUrl, onEditLogo, onPickColor, onSaved),
  ));
}

Widget _app(
  ThemeData? theme,
  _FakeService service,
  Future<void> Function(Uri)? onOpenUrl,
  Future<void> Function(BuildContext)? onEditLogo,
  Future<Color?> Function(BuildContext, Color)? onPickColor,
  VoidCallback? onSaved,
) {
  return MaterialApp(
    theme: theme ?? AppTheme.dark(),
    home: PublicCardSettingsPage(
      service: service,
      identity: const PreviewIdentity(
        fullName: 'Awa Diop',
        jobTitle: 'Directrice générale',
        company: 'Entreprise Exemple',
      ),
      onOpenUrl: onOpenUrl,
      onEditLogo: onEditLogo,
      onPickColor: onPickColor,
      onEditInfo: (_) async {},
      onSaved: onSaved,
    ),
  );
}

PublicCardLivePreview _preview(WidgetTester tester) =>
    tester.widget<PublicCardLivePreview>(find.byType(PublicCardLivePreview));

bool _isOn(WidgetTester tester, String section) =>
    tester.widget<Switch>(find.byKey(Key('switch-$section'))).value;

bool _canSave(WidgetTester tester) =>
    tester.widget<AuthPrimaryButton>(find.byKey(const Key('save'))).onTap != null;

/// Le toast partagé (FeedbackOverlay) se retire tout seul après quelques
/// secondes : on laisse passer ce délai avant la fin du test.
Future<void> _dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('chargement', () {
    testWidgets('affiche un indicateur, puis les réglages enregistrés',
        (tester) async {
      final service = _FakeService(
        settings: const PublicCardSettings(layout: 'banner', theme: 'light'),
      );
      await _pump(tester, service);

      // Chargement : le loader partagé de l'app.
      expect(find.byType(AppLoader), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.byType(AppLoader), findsNothing);
      expect(_preview(tester).settings.layout, 'banner');
      expect(_preview(tester).settings.theme, 'light');
      // Rien à enregistrer tant que rien n'a changé.
      expect(_canSave(tester), isFalse);
    });

    testWidgets('par défaut : carte physique, sombre, mat, or',
        (tester) async {
      await _pump(tester, _FakeService());
      await tester.pumpAndSettle();

      expect(_preview(tester).settings, const PublicCardSettings());
      expect(_preview(tester).accent.color, _gold);
    });

    testWidgets('erreur réseau : message et « Réessayer »', (tester) async {
      final service = _FakeService()..fetchFails = true;
      await _pump(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger vos réglages. Réessayez.'),
          findsOneWidget);
      expect(find.byKey(const Key('save')), findsNothing);

      service.fetchFails = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.byType(PublicCardLivePreview), findsOneWidget);
      expect(service.calls, ['fetch', 'fetch']);
    });
  });

  group('aperçu en direct', () {
    testWidgets(
        'trois dispositions (celles du site en ligne) changent l\'aperçu',
        (tester) async {
      final service = _FakeService();
      await _pump(tester, service);
      await tester.pumpAndSettle();

      for (final layout in PublicCardSettings.layouts) {
        await tester.tap(find.byKey(Key('layout-$layout')));
        await tester.pump();
        expect(_preview(tester).settings.layout, layout);
      }
      expect(PublicCardSettings.layouts, ['physical', 'classic', 'banner']);
      expect(find.byType(PublicCardThumbnail), findsNWidgets(3));
      // Bento et Éditorial ne sont pas proposés tant que le site ne les
      // affiche pas.
      expect(find.text('Bento'), findsNothing);
      expect(find.text('Éditorial'), findsNothing);
      // Rien n'est envoyé tant qu'on n'enregistre pas.
      expect(service.calls, ['fetch']);
    });

    testWidgets('thème et style changent ; le style ne concerne que la carte',
        (tester) async {
      await _pump(tester, _FakeService());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('style-marine')));
      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pump();
      expect(_preview(tester).settings.cardStyle, 'marine');
      expect(_preview(tester).settings.theme, 'light');

      await tester.tap(find.byKey(const Key('layout-classic')));
      await tester.pump();
      expect(find.text('Style de la carte'), findsNothing);
      expect(_canSave(tester), isTrue);
    });

    testWidgets('« Voir ↗ » ouvre la page avec les réglages en cours',
        (tester) async {
      Uri? opened;
      await _pump(tester, _FakeService(),
          onOpenUrl: (url) async => opened = url);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('layout-banner')));
      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('see-public-page')));

      expect(
        opened.toString(),
        'https://kart.business/card/awa-diop?layout=banner&theme=light&style=mat',
      );
    });
  });

  group('couleur d\'accent', () {
    testWidgets('une pastille change l\'aperçu, puis accent_color',
        (tester) async {
      final service = _FakeService();
      await _pump(tester, service);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accent-#4F8EF7')));
      await tester.pump();
      expect(_preview(tester).accent.color, _blue);
      // Texte du bouton plein : noir ou blanc selon la luminance.
      expect(_preview(tester).accent.onColor, PublicCardStyles.onColor(_blue));
      expect(service.calls, ['fetch']);

      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();

      expect(service.savedAccent, '#4F8EF7');
      // Même champ que « Couleur et logo » ; la présentation n'a pas changé.
      expect(service.calls, ['fetch', 'card', 'fetch']);
      expect(_preview(tester).accent.color, _blue);
      expect(_canSave(tester), isFalse);
      await _dismissToast(tester);
    });

    testWidgets('« + » : une couleur trop sombre est éclaircie',
        (tester) async {
      const tooDark = Color(0xFF101014);
      await _pump(tester, _FakeService(),
          onPickColor: (_, __) async => tooDark);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accent-custom')));
      await tester.pumpAndSettle();

      final chosen = _preview(tester).accent.color;
      expect(chosen, isNot(tooDark));
      expect(
        PublicCardStyles.contrast(chosen, const Color(0xFF0E0E10)),
        greaterThanOrEqualTo(3),
      );
      // Message : le toast partagé de l'app.
      expect(find.text('Couleur ajustée'), findsOneWidget);
      await _dismissToast(tester);
    });

    testWidgets('« + » : une couleur lisible est gardée telle quelle',
        (tester) async {
      const teal = Color(0xFF14B8A6);
      await _pump(tester, _FakeService(), onPickColor: (_, __) async => teal);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accent-custom')));
      await tester.pumpAndSettle();

      expect(_preview(tester).accent.color, teal);
      expect(find.text('Couleur ajustée'), findsNothing);
    });

    testWidgets('habillage entreprise : pastilles inactives, cadenas, mention',
        (tester) async {
      final service = _FakeService(
        accent: const EffectiveAccent(
          color: _navy,
          onColor: Colors.white,
          fromCompany: true,
        ),
      );
      var picker = 0;
      await _pump(tester, service,
          onPickColor: (_, __) async {
            picker++;
            return _blue;
          },
          onEditLogo: (_) async {});
      await tester.pumpAndSettle();

      expect(find.text('Couleur définie par votre entreprise'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byKey(const Key('edit-logo')), findsNothing);

      await tester.tap(find.byKey(const Key('accent-#4F8EF7')),
          warnIfMissed: false);
      await tester.tap(find.byKey(const Key('accent-custom')),
          warnIfMissed: false);
      await tester.pump();

      // L'aperçu garde la couleur de l'entreprise, rien n'est à enregistrer.
      expect(picker, 0);
      expect(_preview(tester).accent.color, _navy);
      expect(_canSave(tester), isFalse);
    });

    testWidgets('« Changer le logo → » ouvre la feuille et relit la couleur',
        (tester) async {
      final service = _FakeService();
      var opened = 0;
      await _pump(tester, service, onEditLogo: (_) async {
        opened++;
        service.accent =
            const EffectiveAccent(color: _navy, onColor: Colors.white);
      });
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-logo')));
      await tester.pumpAndSettle();

      expect(opened, 1);
      expect(_preview(tester).accent.color, _navy);
    });

    testWidgets('la couleur suit le thème prévisualisé', (tester) async {
      await _pump(
        tester,
        _FakeService(
          accent: const EffectiveAccent(
            color: _gold,
            onColor: Colors.black,
            byTheme: {
              'dark': EffectiveAccent(color: _gold, onColor: Colors.black),
              'light': EffectiveAccent(color: _navy, onColor: Colors.white),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pump();

      expect(_preview(tester).accent.color, _navy);
    });
  });

  group('enregistrement', () {
    testWidgets('envoie la présentation et confirme', (tester) async {
      final service = _FakeService();
      var savedCallbacks = 0;
      await _pump(tester, service, onSaved: () => savedCallbacks++);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('layout-banner')));
      await tester.tap(find.byKey(const Key('switch-bio')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();

      expect(service.savedSettings!.layout, 'banner');
      expect(service.savedSettings!.hiddenSections, ['bio']);
      // Ni la visibilité des contacts ni la couleur n'ont changé.
      expect(service.calls, ['fetch', 'save']);
      // Succès : le toast partagé de l'app, en haut de l'écran — il ne
      // cache pas la barre Réinitialiser / Enregistrer.
      final toast = find.text('Carte publique mise à jour');
      expect(toast, findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.getRect(toast).bottom,
          lessThan(tester.getRect(find.byKey(const Key('save'))).top));
      expect(savedCallbacks, 1);
      expect(_canSave(tester), isFalse);
      await _dismissToast(tester);
    });

    testWidgets('téléphone, email, réseaux et site pilotent activated_fields',
        (tester) async {
      final service = _FakeService(activatedFields: ['phone', 'email']);
      await _pump(tester, service);
      await tester.pumpAndSettle();

      expect(_isOn(tester, 'phone'), isTrue);
      expect(_isOn(tester, 'socials'), isFalse);

      await tester.tap(find.byKey(const Key('switch-phone')));
      await tester.tap(find.byKey(const Key('switch-socials')));
      await tester.pump();

      // Sans téléphone, WhatsApp ne peut pas s'afficher.
      expect(_isOn(tester, 'whatsapp'), isFalse);
      expect(find.text("Activez d'abord le téléphone"), findsOneWidget);

      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();

      // Un seul interrupteur pour les quatre réseaux.
      expect(service.savedFields,
          ['email', 'facebook', 'github', 'instagram', 'linkedin']);
      expect(service.savedAccent, isNull);
      expect(service.calls, ['fetch', 'card']);
      await _dismissToast(tester);
    });

    testWidgets('échec : message, et les changements restent à enregistrer',
        (tester) async {
      final service = _FakeService()..saveFails = true;
      await _pump(tester, service);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('theme-light')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();

      // Erreur : le toast d'erreur partagé de l'app.
      expect(find.text('Enregistrement impossible'), findsOneWidget);
      expect(
        find.text("Vos réglages n'ont pas pu être enregistrés. Réessayez."),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
      expect(_preview(tester).settings.theme, 'light');
      expect(_canSave(tester), isTrue);
      await _dismissToast(tester);
    });

    testWidgets('« Réinitialiser » ne remet que la présentation',
        (tester) async {
      final service = _FakeService(
        settings: const PublicCardSettings(
          layout: 'banner',
          theme: 'light',
          hiddenSections: ['bio'],
        ),
      );
      await _pump(tester, service);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('accent-#4F8EF7')));
      await tester.tap(find.byKey(const Key('reset')));
      await tester.pump();

      expect(_preview(tester).settings, const PublicCardSettings());
      expect(_isOn(tester, 'bio'), isTrue);
      // Ni les contacts ni la couleur choisie ne sont touchés.
      expect(_isOn(tester, 'phone'), isTrue);
      expect(_preview(tester).accent.color, _blue);

      await tester.tap(find.byKey(const Key('save')));
      await tester.pumpAndSettle();
      expect(service.savedSettings, const PublicCardSettings());
      await _dismissToast(tester);
    });
  });

  testWidgets('onze sections, libellés de la maquette, sans « Adresse »',
      (tester) async {
    await _pump(tester, _FakeService());
    await tester.pumpAndSettle();

    for (final label in [
      'Bio', 'Téléphone mobile', 'WhatsApp', 'Email', 'Site web', //
      'Réseaux sociaux', 'Entreprise', 'Compétences', 'Expériences',
      'Formations', "Centres d'intérêt",
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Adresse'), findsNothing);
  });

  testWidgets('« Faire défiler → » seulement si les vignettes débordent',
      (tester) async {
    await _pump(tester, _FakeService());
    await tester.pumpAndSettle();
    // 390 px : les trois vignettes tiennent.
    expect(find.text('Faire défiler →'), findsNothing);

    await _pump(tester, _FakeService(), size: const Size(320, 2600));
    await tester.pumpAndSettle();
    expect(find.text('Faire défiler →'), findsOneWidget);
  });

  for (final layout in PublicCardSettings.layouts) {
    for (final theme in PublicCardSettings.themes) {
      testWidgets(
          'aperçu $layout / $theme : le cadre s\'arrête sous le bouton',
          (tester) async {
        tester.view.physicalSize = const Size(390, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Posé seul dans un grand espace libre : il ne doit pas s'étirer.
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 358,
                child: PublicCardLivePreview(
                  settings: PublicCardSettings(layout: layout, theme: theme),
                  accent: EffectiveAccent.fallback,
                  identity: const PreviewIdentity(
                    fullName: 'Awa Diop',
                    jobTitle: 'Directrice générale',
                    company: 'Entreprise Exemple',
                  ),
                ),
              ),
            ),
          ),
        ));

        final frame = tester.getRect(find.byType(PublicCardLivePreview));
        final button =
            tester.getRect(find.byKey(const Key('preview-save-button')));
        // Sous le bouton : seulement la marge intérieure du cadre (16 px)
        // et son contour.
        expect(frame.bottom - button.bottom, closeTo(17, 1));
      });
    }
  }

  testWidgets('l\'aperçu écrit les vraies infos de la carte', (tester) async {
    await _pump(tester, _FakeService());
    await tester.pumpAndSettle();

    final preview = find.byType(PublicCardLivePreview);
    for (final text in ['Awa Diop', 'Directrice générale', 'Entreprise Exemple', 'AD']) {
      expect(find.descendant(of: preview, matching: find.text(text)), findsOneWidget);
    }
  });

  testWidgets('composants partagés : barre en verre, boutons, interrupteurs',
      (tester) async {
    await _pump(tester, _FakeService());
    await tester.pumpAndSettle();

    expect(find.byType(GlassAppBar), findsOneWidget);
    expect(find.byType(AuthOutlineButton), findsOneWidget); // Réinitialiser
    expect(find.byType(AuthPrimaryButton), findsOneWidget); // Enregistrer
    expect(find.byType(Switch), findsNWidgets(11));
    // Les deux barres floutent ce qui défile dessous.
    expect(find.byType(BackdropFilter), findsNWidgets(2));
  });

  testWidgets('le contenu défile sous les deux barres', (tester) async {
    await _pump(tester, _FakeService(), size: const Size(390, 844));
    await tester.pumpAndSettle();

    final list = find.byType(ListView).first;
    // La liste occupe toute la hauteur de l'écran, barres comprises.
    expect(tester.getRect(list).top, 0);
    expect(tester.getRect(list).bottom, 844);

    // En haut : le premier élément est sous la barre, entièrement visible.
    final bar = tester.getRect(find.byType(GlassAppBar));
    final previewTop = tester.getRect(find.byType(PublicCardLivePreview)).top;
    expect(previewTop, greaterThanOrEqualTo(bar.bottom));
    // … et juste sous elle, sans grand vide.
    expect(previewTop - bar.bottom, lessThanOrEqualTo(24));

    // Tout en bas : le dernier élément reste au-dessus de la barre du bas.
    final position = tester
        .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first)
        .position;
    // La hauteur totale n'est connue qu'en avançant (liste paresseuse) :
    // on saute jusqu'à ne plus pouvoir descendre.
    for (var i = 0; i < 10; i++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(position.pixels, position.maxScrollExtent);
    expect(tester.getRect(find.text('Modifier mes infos →')).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(const Key('save'))).top));
  });

  testWidgets('ouvert par une vraie navigation : flèche retour dans la barre',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Comme dans l'app : un écran (la Carte) pousse « Ma carte publique »
    // par une MaterialPageRoute, comme publicCardSettingsRoute().
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => CardProvider(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PublicCardSettingsPage(
                      service: _FakeService(),
                      identity: const PreviewIdentity(fullName: 'Awa Diop'),
                    ),
                  ),
                ),
                child: const Text('Personnaliser ma carte'),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Personnaliser ma carte'));
    await tester.pumpAndSettle();

    // La flèche retour standard est dans la barre en verre, visible.
    final back = find.descendant(
        of: find.byType(GlassAppBar), matching: find.byType(BackButton));
    expect(back, findsOneWidget);
    final bar = tester.getRect(find.byType(GlassAppBar));
    expect(bar.contains(tester.getCenter(back)), isTrue);
    expect(tester.getSize(back).height, greaterThanOrEqualTo(44));

    // Sans changement en cours, elle ramène à l'écran précédent.
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byType(PublicCardSettingsPage), findsNothing);
    expect(find.text('Personnaliser ma carte'), findsOneWidget);
  });

  testWidgets('quitter avec des changements : confirmation partagée',
      (tester) async {
    await _pump(tester, _FakeService());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-light')));
    await tester.pump();

    // Retour (bouton de la barre ou geste du système).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Quitter sans enregistrer ?'), findsOneWidget);

    await tester.tap(find.text('Rester'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicCardLivePreview), findsOneWidget);
  });

  for (final dark in [true, false]) {
    testWidgets(
        'iPhone SE (320 × 568), thème ${dark ? 'sombre' : 'clair'} : rien ne déborde',
        (tester) async {
      await _pump(
        tester,
        _FakeService(),
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        size: const Size(320, 568),
      );
      await tester.pumpAndSettle();

      // Un débordement ferait échouer le test.
      expect(find.text('Ma carte publique'), findsOneWidget);
      expect(find.byKey(const Key('save')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('Modifier mes infos →'), findsOneWidget);
    });
  }

  group('effective_accent', () {
    test('lit la couleur, sa source et la valeur par thème', () {
      final accent = EffectiveAccent.tryParse({
        'color': '#0B2B5B',
        'on_color': '#FFFFFF',
        'source': 'company',
        'by_theme': {
          'dark': {'color': '#0B2B5B', 'on_color': '#FFFFFF'},
          'light': {'color': '#c99a2e', 'on_color': '#000000'},
        },
      })!;

      expect(accent.color, _navy);
      expect(accent.onColor, Colors.white);
      expect(accent.fromCompany, isTrue);
      expect(accent.forTheme('light').color, _gold);
      expect(accent.forTheme('inconnu').color, _navy);
    });

    test('absent ou invalide : null, pour garder le repli', () {
      expect(EffectiveAccent.tryParse(null), isNull);
      expect(EffectiveAccent.tryParse({'color': 'bleu'}), isNull);
    });
  });

  group('styles (mêmes règles que le site)', () {
    test('accent en texte : ajusté jusqu\'à 4,5:1, sinon inchangé', () {
      const lightPage = [Color(0xFFF4F1EA), Color(0xFFFFFFFF)];
      const darkPage = [Color(0xFF0B0B0C), Color(0xFF151517)];

      // Or sur fond clair : assombri.
      final onLight = PublicCardStyles.readableAccent(_gold, lightPage);
      expect(onLight, isNot(_gold));
      for (final background in lightPage) {
        expect(PublicCardStyles.contrast(onLight, background),
            greaterThanOrEqualTo(4.5));
      }
      // Or sur fond sombre : déjà lisible.
      expect(PublicCardStyles.readableAccent(_gold, darkPage), _gold);
      // Marine sur fond sombre : éclairci.
      final navyOnDark = PublicCardStyles.readableAccent(_navy, darkPage);
      expect(PublicCardStyles.contrast(navyOnDark, darkPage.last),
          greaterThanOrEqualTo(4.5));
    });

    test('styles de carte : valeurs du site en ligne', () {
      final mat = PublicCardStyles.cardLook('mat', _gold);
      expect(mat.gradient.colors.toSet(), {const Color(0xFF121213)});
      expect(mat.text, const Color(0xFFF4F1EA));
      // La carte de derrière est de la couleur d'accent.
      expect(mat.back, _gold);

      // Dégradé : la carte elle-même est de la couleur d'accent.
      final gradient = PublicCardStyles.cardLook('gradient', _gold);
      expect(gradient.gradient.colors.first, _gold);
      expect(gradient.text, PublicCardStyles.onColor(_gold));
      expect(gradient.back, isNot(_gold));

      final marine = PublicCardStyles.cardLook('marine', _gold);
      expect(marine.gradient.colors,
          const [Color(0xFF0B2B5B), Color(0xFF061A38)]);
      expect(marine.text, Colors.white);
      expect(marine.back, _gold);
    });
  });
}

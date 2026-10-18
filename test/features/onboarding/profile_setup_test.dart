import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/onboarding/data/profile_setup_api.dart';
import 'package:kart_app/features/onboarding/ui/profile_setup/profile_setup_page.dart';
import 'package:kart_app/shared/widgets/auth_primary_button.dart';
import 'package:provider/provider.dart';

/// Faux serveur : carte de départ donnée, enregistrements notés.
class _FakeApi extends ProfileSetupApi {
  _FakeApi(this.card);
  final Map<String, dynamic> card;
  final List<Map<String, dynamic>> saved = [];

  @override
  Future<Map<String, dynamic>> fetchCard() async => card;

  @override
  Future<void> saveCard(Map<String, dynamic> fields) async => saved.add(fields);
}

class _FakeAuth extends AuthProvider {
  _FakeAuth({String? email, String? avatar}) {
    user = User(id: 1, firstname: 'Awa', lastname: 'Diop', email: email ?? 'awa.diop@example.test', avatar: avatar, plan: 'pro', onboardingRequired: true);
  }
  int completed = 0;
  final List<String> uploads = [];

  @override
  Future<bool> completeOnboarding() async {
    completed++;
    return true;
  }

  @override
  Future<void> updateAvatar(Uint8List bytes, String filename) async {
    uploads.add(filename);
    user = User(id: 1, firstname: 'Awa', lastname: 'Diop', email: user!.email, avatar: 'avatars/awa.jpg', plan: 'pro');
    notifyListeners();
  }
}

Future<void> _pump(WidgetTester tester, _FakeAuth auth, _FakeApi api, {bool withPicker = false}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: ProfileSetupPage(
        api: api,
        pickAvatar: withPicker ? (_) async => (Uint8List.fromList([1, 2, 3]), 'awa.jpg') : null,
      ),
      routes: {'/home': (_) => const Scaffold(body: Text('ACCUEIL'))},
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tapPrimary(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onboarding-primary')));
  await tester.pumpAndSettle();
}

Future<void> _later(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('onboarding-later')));
  await tester.pumpAndSettle();
}

bool _primaryEnabled(WidgetTester tester) =>
    tester.widget<AuthPrimaryButton>(find.byKey(const Key('onboarding-primary'))).onTap != null;

bool _switchValue(WidgetTester tester, String key) =>
    tester.widget<Switch>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(Switch))).value;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
    for (final f in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
      await (FontLoader(f.key)..addFont(Future.value(ByteData.view(File(f.value).readAsBytesSync().buffer)))).load();
    }
  });

  testWidgets('« Plus tard » à chaque étape : rien n\'est enregistré, la fin est notée', (tester) async {
    final auth = _FakeAuth();
    final api = _FakeApi({'is_public': true, 'listed_in_directory': false, 'activated_fields': []});
    await _pump(tester, auth, api);

    for (var i = 0; i < 4; i++) {
      await _later(tester);
    }

    expect(api.saved, isEmpty);
    expect(auth.completed, 1);
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('« Passer » termine tout de suite', (tester) async {
    final auth = _FakeAuth();
    await _pump(tester, auth, _FakeApi({}));

    await tester.tap(find.byKey(const Key('onboarding-skip-all')));
    await tester.pumpAndSettle();

    expect(auth.completed, 1);
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('photo : ajoutée puis « Continuer »', (tester) async {
    final auth = _FakeAuth();
    await _pump(tester, auth, _FakeApi({}), withPicker: true);

    expect(find.text('Ajouter une photo'), findsOneWidget);
    await _tapPrimary(tester);

    expect(auth.uploads, ['awa.jpg']);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('poste et entreprise : préremplis, enregistrés sans jamais envoyer l\'e-mail', (tester) async {
    final api = _FakeApi({'job_title': 'Commerciale', 'company': '', 'email': 'awa.diop@example.test'});
    await _pump(tester, _FakeAuth(), api);
    await _later(tester); // photo

    expect(find.text('Commerciale'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Entreprise Exemple');
    await _tapPrimary(tester);

    expect(api.saved.single, {'job_title': 'Commerciale', 'company': 'Entreprise Exemple'});
  });

  testWidgets('contact : téléphone prérempli, champs déjà affichés conservés', (tester) async {
    final api = _FakeApi({'phone': '+221 77 000 00 01', 'activated_fields': ['linkedin']});
    await _pump(tester, _FakeAuth(), api);
    await _later(tester);
    await _later(tester);

    expect(find.text('+221 77 000 00 01'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('onboarding-whatsapp')), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    await _tapPrimary(tester);

    final saved = api.saved.single;
    expect(saved['phone'], '+221 77 000 00 01');
    expect((saved['activated_fields'] as List).toSet(), {'linkedin', 'phone', 'whatsapp'});
    expect(saved.containsKey('email'), isFalse);
  });

  testWidgets('contact : « Continuer » exige au moins un moyen affiché', (tester) async {
    await _pump(tester, _FakeAuth(email: 'visiteur-221770000001@kart-evenement.local'), _FakeApi({'activated_fields': []}));
    await _later(tester);
    await _later(tester);

    expect(_primaryEnabled(tester), isFalse);
    await tester.enterText(find.byType(TextField).first, '+221770000001');
    await tester.pumpAndSettle();
    expect(_primaryEnabled(tester), isTrue);
  });

  testWidgets('contact : l\'adresse interne @kart-evenement.local n\'est jamais proposée', (tester) async {
    const placeholder = 'visiteur-221770000001@kart-evenement.local';
    await _pump(
      tester,
      _FakeAuth(email: placeholder),
      _FakeApi({'email': placeholder, 'phone': '+221770000001', 'activated_fields': ['email']}),
    );
    await _later(tester);
    await _later(tester);

    expect(find.byKey(const Key('onboarding-show-email')), findsNothing);
    expect(find.textContaining('kart-evenement.local'), findsNothing);
  });

  testWidgets('contact : un vrai e-mail est proposé, non coché d\'office', (tester) async {
    await _pump(tester, _FakeAuth(), _FakeApi({'email': 'awa.diop@example.test', 'activated_fields': []}));
    await _later(tester);
    await _later(tester);

    expect(find.text('awa.diop@example.test'), findsOneWidget);
    expect(_switchValue(tester, 'onboarding-show-email'), isFalse);
  });

  testWidgets('visibilité : Explorer jamais activé d\'office, et grisé sans carte publique', (tester) async {
    final auth = _FakeAuth();
    final api = _FakeApi({'is_public': true, 'listed_in_directory': false});
    await _pump(tester, auth, api);
    for (var i = 0; i < 3; i++) {
      await _later(tester);
    }

    expect(_switchValue(tester, 'onboarding-public'), isTrue);
    expect(_switchValue(tester, 'onboarding-listed'), isFalse);
    expect(find.textContaining('fonctionnent dans tous les cas'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byKey(const Key('onboarding-public')), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(find.text("Rendez d'abord votre carte publique."), findsOneWidget);
    expect(tester.widget<Switch>(find.descendant(of: find.byKey(const Key('onboarding-listed')), matching: find.byType(Switch))).onChanged, isNull);

    await _tapPrimary(tester);
    expect(api.saved.single, {'is_public': false, 'listed_in_directory': false});
    expect(auth.completed, 1);
  });
}

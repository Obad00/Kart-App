import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/profile/widgets/edit_profile_form.dart';
import 'package:kart_app/features/profile_completion/model/profile_completion_model.dart';
import 'package:kart_app/features/profile_completion/providers/profile_completion_provider.dart';
import 'package:kart_app/features/profile_completion/services/profile_completion_service.dart';
import 'package:kart_app/features/profile_completion/ui/completion_form_page.dart';
import 'package:provider/provider.dart';

/// « Modifier mes infos » : libellés de visibilité et confirmation avant de
/// désactiver la carte. Données fictives.
class _FakeService extends ProfileCompletionService {
  @override
  Future<ProfileCompletionModel> fetch() async => ProfileCompletionModel.fromJson({
        'firstname': 'Awa',
        'lastname': 'Diop',
        'job_title': 'Commerciale',
        'company': 'Entreprise Exemple',
        'is_public': true,
        'listed_in_directory': true,
        'activated_fields': <String>[],
      });
}

class _FakeAuth extends AuthProvider {
  _FakeAuth() {
    user = User(id: 1, firstname: 'Awa', lastname: 'Diop', email: 'awa.diop@example.test', plan: 'pro');
  }
}

Future<void> pumpCompletionForm(WidgetTester tester, {ThemeData? theme}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuth()),
      ChangeNotifierProvider<ProfileCompletionProvider>(create: (_) => ProfileCompletionProvider(_FakeService())),
    ],
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: theme ?? AppTheme.dark(), home: const Scaffold(body: CompletionFormPage(section: 'basic'))),
  ));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.byKey(const Key('listed-in-directory')), 300, scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

bool _switchOn(WidgetTester tester, String key) =>
    tester.widget<Switch>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(Switch))).value;

Future<void> loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
  for (final f in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
    await (FontLoader(f.key)..addFont(Future.value(ByteData.view(File(f.value).readAsBytesSync().buffer)))).load();
  }
}

void main() {
  setUpAll(loadFonts);

  testWidgets('libellés : « Carte active » et « Visible dans l\'annuaire Explorer »', (tester) async {
    await pumpCompletionForm(tester);

    expect(find.text('Carte active (lien, QR code et carte NFC)'), findsOneWidget);
    expect(find.text("Visible dans l'annuaire Explorer"), findsOneWidget);
    expect(find.text('Rendre ma carte publique'), findsNothing);
    expect(find.text('Apparaître dans Explorer'), findsNothing);
  });

  testWidgets('email de la carte et email de connexion : deux champs distincts', (tester) async {
    await pumpCompletionForm(tester);
    expect(find.text('Email affiché sur la carte'), findsOneWidget);
    expect(find.text('Email (connexion et carte)'), findsNothing);

    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: _FakeAuth(),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SingleChildScrollView(child: EditProfileForm())),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Email de connexion'), findsOneWidget);
  });

  testWidgets('désactiver la carte : « Annuler » ne change rien, « Continuer » désactive', (tester) async {
    await pumpCompletionForm(tester);
    final cardSwitch = find.descendant(of: find.byKey(const Key('card-active')), matching: find.byType(Switch));

    await tester.tap(cardSwitch);
    await tester.pumpAndSettle();
    expect(find.text('Votre lien, votre QR code et votre carte NFC ne fonctionneront plus. Continuer ?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const Key('card-deactivation-dialog')), matching: find.text('Annuler')));
    await tester.pumpAndSettle();
    expect(_switchOn(tester, 'card-active'), isTrue);
    expect(_switchOn(tester, 'listed-in-directory'), isTrue);

    await tester.tap(cardSwitch);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('card-deactivation-confirm')));
    await tester.pumpAndSettle();
    expect(_switchOn(tester, 'card-active'), isFalse);
    expect(_switchOn(tester, 'listed-in-directory'), isFalse);
    expect(find.text("Activez d'abord votre carte."), findsOneWidget);

    // Réactiver : aucune confirmation.
    await tester.tap(cardSwitch);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-deactivation-dialog')), findsNothing);
    expect(_switchOn(tester, 'card-active'), isTrue);
  });
}

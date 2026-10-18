import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/auth/ui/consent_page.dart';
import 'package:kart_app/features/auth/ui/register_page.dart';
import 'package:kart_app/shared/widgets/auth_primary_button.dart';
import 'package:provider/provider.dart';

/// Faux fournisseur : enregistre les appels, sans réseau.
class _FakeAuth extends AuthProvider {
  int accepted = 0;
  Map<String, dynamic>? registered;

  @override
  Future<bool> acceptConsents() async {
    accepted++;
    return true;
  }

  @override
  Future<void> register({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
    required bool acceptedTerms,
  }) async {
    registered = {'email': email, 'accepted_terms': acceptedTerms};
  }
}

Widget _app(AuthProvider auth, Widget home) => ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: home,
        routes: {'/home': (_) => const Scaffold(body: Text('ACCUEIL'))},
      ),
    );

AuthPrimaryButton _button(WidgetTester tester, String label) => tester.widget<AuthPrimaryButton>(
    find.widgetWithText(AuthPrimaryButton, label));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
    // Vraies polices : la police de test dessine chaque lettre en carré,
    // bien plus large, et ferait déborder des lignes qui tiennent en vrai.
    for (final font in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
      final bytes = File(font.value).readAsBytesSync();
      await (FontLoader(font.key)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  group('/me', () {
    test('consent_required est lu ; absent (serveur plus ancien) = rien à demander', () {
      User parse(Map<String, dynamic> extra) =>
          User.fromJson({'id': 1, 'firstname': 'Awa', 'lastname': 'Diop', 'email': 'awa@example.com', ...extra});

      expect(parse({'consent_required': true}).consentRequired, isTrue);
      expect(parse({'consent_required': false}).consentRequired, isFalse);
      expect(parse({}).consentRequired, isFalse);
    });
  });

  group('écran d\'acceptation à la connexion', () {
    testWidgets('case jamais pré-cochée ; Continuer seulement une fois cochée', (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(_app(auth, const ConsentPage()));

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(_button(tester, 'Continuer').onTap, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_button(tester, 'Continuer').onTap, isNotNull);

      await tester.tap(find.byKey(const Key('consent-submit')));
      await tester.pumpAndSettle();

      expect(auth.accepted, 1);
      expect(find.text('ACCUEIL'), findsOneWidget);
    });
  });

  group('inscription dans l\'app', () {
    testWidgets('« Créer mon compte » exige la case, et l\'accord est envoyé', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final auth = _FakeAuth();
      await tester.pumpWidget(_app(auth, const RegisterPage()));
      await tester.pumpAndSettle();

      Future<void> fill(List<String> values) async {
        final fields = find.byType(TextField);
        for (var i = 0; i < values.length; i++) {
          await tester.enterText(fields.at(i), values[i]);
        }
        await tester.pump();
      }

      await fill(['Awa', 'Diop']);
      await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Continuer'));
      await tester.pumpAndSettle();
      await fill(['+221770000001', 'awa@example.com']);
      await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Continuer'));
      await tester.pumpAndSettle();
      await fill(['password123', 'password123']);

      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      expect(_button(tester, 'Créer mon compte').onTap, isNull);

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(_button(tester, 'Créer mon compte').onTap, isNotNull);

      await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Créer mon compte'));
      await tester.pump();
      expect(auth.registered?['accepted_terms'], isTrue);
    });
  });
}

// Vérification d'email : écran du code (6 chiffres, compte à rebours donné
// par le serveur), bandeau non bloquant, passage obligatoire dans HomeShell.
// Données fictives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/data/email_verification_service.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/auth/ui/email_verification_page.dart';
import 'package:kart_app/features/auth/widgets/email_verification_banner.dart';
import 'package:kart_app/features/navigation/home_shell.dart';
import 'package:provider/provider.dart';

User _user({bool required = false, bool banner = false, int retryAfter = 0, bool verified = false}) => User.fromJson({
      'id': 1,
      'firstname': 'Awa',
      'lastname': 'Exemple',
      'email': 'awa@example.com',
      'plan': 'pro',
      'email_verified': verified,
      'email_verification_required': required,
      'email_verification_banner': banner,
      'email_verification_retry_after': retryAfter,
    });

class _FakeAuth extends AuthProvider {
  _FakeAuth(User initial) {
    user = initial;
  }

  User? afterLoadMe;
  int loads = 0;

  @override
  bool get isInitialized => true;

  @override
  Future<void> loadMe() async {
    loads++;
    if (afterLoadMe != null) {
      user = afterLoadMe;
      notifyListeners();
    }
  }
}

class _FakeService extends EmailVerificationService {
  final codes = <String>[];
  int resends = 0;
  CodeResult next = const CodeResult(verified: false, status: 'invalid', attemptsLeft: 4, message: 'Code incorrect. Essais restants : 4.');
  ResendResult resendResult = const ResendResult(sent: true, retryAfter: 60);

  @override
  Future<CodeResult> verifyCode(String code) async {
    codes.add(code);
    return next;
  }

  @override
  Future<ResendResult> resend() async {
    resends++;
    return resendResult;
  }
}

Future<void> _pump(WidgetTester tester, _FakeAuth auth, Widget child) async {
  await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: child,
      routes: {
        '/verify-email': (_) => const Scaffold(body: Text('Écran du code')),
        '/login': (_) => const Scaffold(body: Text('Connexion')),
      },
    ),
  ));
  await tester.pump();
}

void main() {
  test('/me : champs de vérification lus, serveur ancien reconnu', () {
    final user = _user(required: true, retryAfter: 42);
    expect(user.emailVerificationRequired, isTrue);
    expect(user.emailVerificationBanner, isFalse);
    expect(user.emailVerificationRetryAfter, 42);
    expect(user.emailVerificationCodeSupported, isTrue);

    final legacy = User.fromJson({'id': 1, 'firstname': 'Awa', 'lastname': 'Exemple', 'email': 'awa@example.com', 'email_verified': false});
    expect(legacy.emailVerificationRequired, isFalse);
    expect(legacy.emailVerificationCodeSupported, isFalse);
  });

  testWidgets('écran du code : compte à rebours du serveur, code incorrect, renvoi refusé', (tester) async {
    final auth = _FakeAuth(_user(required: true, retryAfter: 42));
    final service = _FakeService();
    await _pump(tester, auth, EmailVerificationPage(service: service));

    expect(find.text('Renvoyer le code dans 0:42'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Renvoyer le code dans 0:40'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email-code-field')), '123456');
    await tester.pump();
    expect(service.codes, ['123456']);
    expect(find.text('Code incorrect. Essais restants : 4.'), findsOneWidget);

    // Lettres refusées, 6 chiffres au plus.
    await tester.enterText(find.byKey(const Key('email-code-field')), '12ab3456789');
    await tester.pump();
    expect(service.codes.length, 2);
    expect(service.codes.last, '123456');

    // Délai écoulé : renvoi refusé par le serveur (limite horaire).
    await tester.pump(const Duration(seconds: 41));
    expect(find.text('Renvoyer le code'), findsOneWidget);
    service.resendResult = const ResendResult(sent: false, retryAfter: 1500, message: 'Patientez 1500 s avant de demander un nouveau code.');
    await tester.tap(find.text('Renvoyer le code'));
    await tester.pump();
    expect(service.resends, 1);
    expect(find.text('Renvoyer le code dans 25:00'), findsOneWidget);
    expect(find.text('Patientez 1500 s avant de demander un nouveau code.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('écran du code ouvert depuis le bandeau : bon code, retour', (tester) async {
    final auth = _FakeAuth(_user(banner: true));
    final service = _FakeService()
      ..next = const CodeResult(verified: true, status: 'verified', attemptsLeft: 5, message: 'Adresse email vérifiée.');
    auth.afterLoadMe = _user(verified: true);

    await _pump(
      tester,
      auth,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EmailVerificationPage(blocking: false, service: service)),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email-code-field')), '042517');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.codes, ['042517']);
    expect(find.text('Ouvrir'), findsOneWidget);
    expect(auth.user!.emailVerified, isTrue);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('bandeau : affiché seulement sans blocage, renvoi avec compte à rebours', (tester) async {
    final service = _FakeService();
    final auth = _FakeAuth(_user(banner: true));
    await _pump(tester, auth, Scaffold(body: EmailVerificationBanner(service: service)));

    expect(find.text('Confirmez votre adresse email'), findsOneWidget);
    await tester.tap(find.text('Renvoyer'));
    await tester.pump();
    expect(service.resends, 1);
    expect(find.text('Renvoyer (1:00)'), findsOneWidget);
    expect(find.text('Email envoyé : saisissez le code ou ouvrez le lien.'), findsOneWidget);

    await tester.tap(find.text('Renvoyer (1:00)'));
    await tester.pump();
    expect(service.resends, 1);

    for (final user in [_user(required: true), _user(verified: true), _user()]) {
      await _pump(tester, _FakeAuth(user), Scaffold(body: EmailVerificationBanner(service: service)));
      expect(find.text('Confirmez votre adresse email'), findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('HomeShell ouvre l\'écran du code pour un compte à vérification obligatoire', (tester) async {
    await _pump(tester, _FakeAuth(_user(required: true)), const HomeShell());
    await tester.pumpAndSettle();
    expect(find.text('Écran du code'), findsOneWidget);
  });
}

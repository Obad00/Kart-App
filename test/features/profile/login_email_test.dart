import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/profile/widgets/login_email.dart';
import 'package:provider/provider.dart';

/// Email de connexion, distinct de l'email de la carte : visible et
/// modifiable (fenêtre dédiée), recopiable sur la carte. Données fictives.
class _FakeAuth extends AuthProvider {
  _FakeAuth({String email = 'awa@example.com'}) {
    user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: email, phone: '+221770000001', plan: 'pro');
  }

  final requested = <String>[];
  String? answer;

  @override
  Future<String?> changeLoginEmail(String email) async {
    requested.add(email);
    if (answer == null) {
      user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: email, plan: 'pro');
      notifyListeners();
    }
    return answer;
  }
}

/// Fausse couche réseau : garde les requêtes, répond comme le serveur.
class _RecordingAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final body = options.method == 'GET'
        ? {'id': 1, 'firstname': 'Awa', 'lastname': 'Exemple', 'email': 'nouveau@example.com', 'phone': '+221770000001', 'plan': 'pro'}
        : {'message': 'Profil mis à jour avec succès'};
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pump(WidgetTester tester, _FakeAuth auth, TextEditingController cardEmail) async {
  await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
    value: auth,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(key: const Key('card-email'), controller: cardEmail),
              LoginEmailNotice(cardEmail: cardEmail, onUseOnCard: (email) => setState(() => cardEmail.text = email)),
            ]),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
  });

  testWidgets('la ligne rappelle l\'email de connexion et le reprend sur la carte', (tester) async {
    final cardEmail = TextEditingController(text: 'pro@example.com');
    await _pump(tester, _FakeAuth(), cardEmail);

    expect(tester.widget<Text>(find.byKey(const Key('login-email-value'))).data, 'awa@example.com');
    expect(find.text('Modifier'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-email-use-on-card')));
    await tester.pumpAndSettle();

    expect(cardEmail.text, 'awa@example.com');
    expect(find.byKey(const Key('login-email-use-on-card')), findsNothing);
  });

  testWidgets('un compte sans email (créé par code) propose d\'en ajouter un', (tester) async {
    await _pump(tester, _FakeAuth(email: 'x123@kart-evenement.local'), TextEditingController());

    expect(find.text('Aucun email de connexion'), findsOneWidget);
    expect(find.text('Ajouter'), findsOneWidget);
    expect(find.textContaining('kart-evenement.local'), findsNothing);
  });

  testWidgets('la fenêtre affiche le refus du serveur, puis enregistre', (tester) async {
    final auth = _FakeAuth()..answer = 'Cette adresse email est déjà utilisée par un autre compte.';
    await _pump(tester, auth, TextEditingController(text: 'pro@example.com'));

    await tester.tap(find.byKey(const Key('login-email-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Email de connexion'), findsWidgets);

    await tester.enterText(find.descendant(of: find.byKey(const Key('login-email-field')), matching: find.byType(TextField)), 'pris@example.com');
    await tester.tap(find.byKey(const Key('login-email-save')));
    await tester.pumpAndSettle();
    expect(find.text('Cette adresse email est déjà utilisée par un autre compte.'), findsOneWidget);

    auth.answer = null;
    await tester.enterText(find.descendant(of: find.byKey(const Key('login-email-field')), matching: find.byType(TextField)), 'nouveau@example.com');
    await tester.tap(find.byKey(const Key('login-email-save')));
    await tester.pumpAndSettle();

    expect(auth.requested, ['pris@example.com', 'nouveau@example.com']);
    expect(find.byKey(const Key('login-email-field')), findsNothing);
    expect(find.text('Email de connexion modifié'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('login-email-value'))).data, 'nouveau@example.com');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('une adresse mal formée est refusée sans appel au serveur', (tester) async {
    final auth = _FakeAuth();
    await _pump(tester, auth, TextEditingController());

    await tester.tap(find.byKey(const Key('login-email-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byKey(const Key('login-email-field')), matching: find.byType(TextField)), 'pas-un-email');
    await tester.tap(find.byKey(const Key('login-email-save')));
    await tester.pumpAndSettle();

    expect(find.text('Saisissez une adresse email valide.'), findsOneWidget);
    expect(auth.requested, isEmpty);
  });

  test('le changement renvoie prénom, nom et téléphone pour ne rien effacer', () async {
    final adapter = _RecordingAdapter();
    final previous = ApiClient.dio.httpClientAdapter;
    ApiClient.dio.httpClientAdapter = adapter;
    addTearDown(() => ApiClient.dio.httpClientAdapter = previous);

    final auth = AuthProvider();
    await Future<void>.delayed(Duration.zero);
    auth.user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: 'awa@example.com', phone: '+221770000001', plan: 'pro');

    final error = await auth.changeLoginEmail(' nouveau@example.com ');

    expect(error, isNull);
    final put = adapter.requests.firstWhere((r) => r.method == 'PUT');
    expect(put.data, {'firstname': 'Awa', 'lastname': 'Exemple', 'phone': '+221770000001', 'email': 'nouveau@example.com'});
    expect(auth.user?.email, 'nouveau@example.com');
  });
}

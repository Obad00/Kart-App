// Compte suspendu (licence de l'entreprise suspendue) : déclenché par
// `suspended` dans /me ou par un 403 `account_suspended`. L'écran ne garde
// que les contacts (lecture, export), la suppression du compte et la
// déconnexion. Données fictives.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/auth/ui/suspended_page.dart';
import 'package:kart_app/features/contacts/models/contact_model.dart';
import 'package:kart_app/features/contacts/models/highlight_group.dart';
import 'package:kart_app/features/contacts/providers/contacts_provider.dart';
import 'package:provider/provider.dart';

const message = 'Votre compte est suspendu. Pour le réactiver, contactez KART.';

class FakeContacts extends ContactsProvider {
  FakeContacts(this.json);
  final List<Map<String, dynamic>> json;

  @override
  Future<void> fetchGroupedContacts() async {
    groups = [
      HighlightGroup.fromJson({
        'highlight': {'id': 0, 'name': 'Sans highlight'},
        'contacts': json,
      }),
    ];
    notifyListeners();
  }
}

class FakeAuth extends AuthProvider {
  FakeAuth({bool suspended = true}) {
    user = User(id: 1, firstname: 'Awa', lastname: 'Diop', email: 'awa.diop@example.test', plan: 'enterprise', suspended: suspended);
  }
  int logouts = 0;
  int meLoads = 0;

  /// Réponse du prochain /me : true = toujours suspendu, false = réactivé,
  /// null = session expirée (déconnexion).
  bool? nextSuspended = true;

  @override
  Future<void> loadMe() async {
    meLoads++;
    user = nextSuspended == null
        ? null
        : User(id: 1, firstname: 'Awa', lastname: 'Diop', email: 'awa.diop@example.test', plan: 'enterprise', suspended: nextSuspended!);
    notifyListeners();
  }

  @override
  Future<void> logout() async {
    logouts++;
    user = null;
    notifyListeners();
  }
}

const sampleContacts = [
  {'id': 1, 'fullname': 'Moussa Exemple', 'job': 'Directeur', 'company': 'Société Exemple', 'phone': '+221 77 000 00 02'},
  {'id': 2, 'fullname': 'Fatou Exemple', 'email': 'fatou@example.test'},
];

Future<void> loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
  for (final f in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
    await (FontLoader(f.key)..addFont(Future.value(ByteData.view(File(f.value).readAsBytesSync().buffer)))).load();
  }
}

Future<void> pumpSuspended(
  WidgetTester tester, {
  required FakeAuth auth,
  List<Map<String, dynamic>> contacts = sampleContacts,
  List<List<ContactModel>>? exported,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<ContactsProvider>(create: (_) => FakeContacts(contacts)),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.dark(),
      home: SuspendedPage(share: (list) async => exported?.add(list), resetSession: (_) {}),
      routes: {
        '/login': (_) => const Scaffold(body: Text('CONNEXION')),
        '/home': (_) => const Scaffold(body: Text('ACCUEIL')),
      },
    ),
  ));
  await tester.pumpAndSettle();
}

/// Adaptateur HTTP factice : chaque requête reçoit la réponse donnée.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(loadFonts);
  tearDown(() => ApiClient.onAccountSuspended = null);

  group('détection', () {
    test('/me : suspended lu ; absent (backend actuel) : false', () {
      expect(User.fromJson({'id': 1, 'email': 'a@example.test', 'suspended': true}).suspended, isTrue);
      expect(User.fromJson({'id': 1, 'email': 'a@example.test', 'suspended': false}).suspended, isFalse);
      expect(User.fromJson({'id': 1, 'email': 'a@example.test'}).suspended, isFalse);
    });

    Future<int> callsFor(int status, String body) async {
      var calls = 0;
      ApiClient.onAccountSuspended = () => calls++;
      final dio = Dio()
        ..httpClientAdapter = _Adapter(status, body)
        ..interceptors.add(AccountSuspendedInterceptor());
      try {
        await dio.get('https://api.example.test/me/card-summary');
      } on DioException catch (_) {}
      return calls;
    }

    test('403 account_suspended, quelle que soit la requête : écran déclenché', () async {
      expect(await callsFor(403, '{"code":"account_suspended","message":"$message"}'), 1);
    });

    test('autres erreurs : rien', () async {
      expect(await callsFor(403, '{"message":"Accès refusé"}'), 0);
      expect(await callsFor(401, '{"message":"Non authentifié."}'), 0);
      expect(await callsFor(200, '{"ok":true}'), 0);
    });

    test('markSuspended : une seule fois ; la déconnexion le remet à zéro', () async {
      final auth = FakeAuth(suspended: false);
      expect(auth.isSuspended, isFalse);
      expect(auth.markSuspended(), isTrue);
      expect(auth.markSuspended(), isFalse);
      expect(auth.isSuspended, isTrue);
      expect(FakeAuth(suspended: true).markSuspended(), isFalse);
    });
  });

  group('écran', () {
    testWidgets('message exact, contacts en lecture, rien d\'autre', (tester) async {
      await pumpSuspended(tester, auth: FakeAuth());

      expect(find.text('Compte suspendu'), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.text('Moussa Exemple'), findsOneWidget);
      expect(find.text('Directeur · Société Exemple'), findsOneWidget);
      expect(find.text('Fatou Exemple'), findsOneWidget);
      expect(find.text('Exporter mes contacts'), findsOneWidget);
      expect(find.text('Supprimer mon compte'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(find.text('Actualiser'), findsOneWidget);

      // Aucun prix, aucun paiement, aucun lien externe.
      expect(find.textContaining(RegExp(r'\d\s?F\b|FCFA|[Pp]rix|[Pp]ayer|[Pp]aiement|https?://|www\.')), findsNothing);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('« Exporter mes contacts » exporte tous les contacts', (tester) async {
      final exported = <List<ContactModel>>[];
      await pumpSuspended(tester, auth: FakeAuth(), exported: exported);

      await tester.tap(find.byKey(const Key('suspended-export')));
      await tester.pumpAndSettle();

      expect(exported.single.map((c) => c.fullname), ['Moussa Exemple', 'Fatou Exemple']);
    });

    testWidgets('sans contact : pas de bouton d\'export', (tester) async {
      await pumpSuspended(tester, auth: FakeAuth(), contacts: const []);

      expect(find.text('Aucun contact.'), findsOneWidget);
      expect(find.byKey(const Key('suspended-export')), findsNothing);
    });

    testWidgets('« Supprimer mon compte » ouvre la suppression', (tester) async {
      await pumpSuspended(tester, auth: FakeAuth());

      await tester.tap(find.byKey(const Key('suspended-delete')));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le compte'), findsOneWidget);
      expect(find.text('Cette action est irréversible. Toutes vos données seront supprimées.'), findsOneWidget);
    });

    testWidgets('« Actualiser » : toujours suspendu, on reste ; réactivé, retour à l\'app', (tester) async {
      final auth = FakeAuth();
      await pumpSuspended(tester, auth: auth);

      await tester.tap(find.byKey(const Key('suspended-reload')));
      await tester.pumpAndSettle();
      expect(auth.meLoads, 1);
      expect(find.text(message), findsOneWidget);

      auth.nextSuspended = false;
      await tester.tap(find.byKey(const Key('suspended-reload')));
      await tester.pumpAndSettle();
      expect(auth.meLoads, 2);
      expect(find.text('ACCUEIL'), findsOneWidget);
    });

    testWidgets('glisser vers le bas recharge /me', (tester) async {
      final auth = FakeAuth()..nextSuspended = false;
      await pumpSuspended(tester, auth: auth);

      await tester.fling(find.text('Compte suspendu'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(auth.meLoads, 1);
      expect(find.text('ACCUEIL'), findsOneWidget);
    });

    testWidgets('actualiser avec une session expirée : connexion', (tester) async {
      final auth = FakeAuth()..nextSuspended = null;
      await pumpSuspended(tester, auth: auth);

      await tester.tap(find.byKey(const Key('suspended-reload')));
      await tester.pumpAndSettle();

      expect(find.text('CONNEXION'), findsOneWidget);
    });

    testWidgets('« Se déconnecter » ramène à la connexion', (tester) async {
      final auth = FakeAuth();
      await pumpSuspended(tester, auth: auth);

      await tester.tap(find.byKey(const Key('suspended-logout')));
      await tester.pumpAndSettle();

      expect(auth.logouts, 1);
      expect(find.text('CONNEXION'), findsOneWidget);
    });
  });
}

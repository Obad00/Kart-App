// Lot E1 (événement du 11 décembre) : reprise unique sur 401, onglet
// Invitations qui garde sa liste en cas d'erreur et passe en lecture seule
// une fois l'événement terminé, actualisation silencieuse des participants,
// affiche jamais recadrée, police système bornée. Données fictives.
import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/company_community/models/company_event_summary.dart';
import 'package:kart_app/features/company_community/ui/company_event_participants_page.dart';
import 'package:kart_app/features/company_community/ui/event_invitations_tab.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/shared/utils/silent_refresh.dart';
import 'package:kart_app/shared/widgets/filter_pill_chip.dart';
import 'package:kart_app/shared/widgets/poster_image.dart';
import 'package:kart_app/shared/widgets/text_scale_clamp.dart';
import 'package:provider/provider.dart';

/// Faux serveur : « METHODE /chemin » → file de réponses (la dernière se
/// répète). Garde les appels et leurs en-têtes Authorization.
class _FakeApi implements HttpClientAdapter {
  final Map<String, List<(int, Object?)>> routes;
  final List<String> calls = [];
  final List<String?> authorizations = [];
  final List<List<int>> requestBodies = [];

  _FakeApi(this.routes);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final key = '${options.method} ${options.uri.path.replaceFirst(RegExp(r'^.*/api'), '')}';
    calls.add(key);
    authorizations.add(options.headers['Authorization'] as String?);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    requestBodies.add(bytes);
    final queue = routes[key];
    final (status, body) = queue == null || queue.isEmpty
        ? (404, {'message': 'absent'})
        : (queue.length > 1 ? queue.removeAt(0) : queue.first);
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _invitation(int id, String name, String status) => {
      'id': id,
      'name': name,
      'first_name': name.split(' ').first,
      'last_name': name.split(' ').skip(1).join(' '),
      'phone': '+22177000000$id',
      'status': status,
      'needs_reminder': false,
      'message': 'Bonjour,\n\nhttps://kart.business/i/AbCdEfGh123$id',
      'whatsapp_url': 'https://wa.me/22177000000$id?text=Bonjour',
    };

Map<String, dynamic> _page({bool ended = false}) => {
      'data': [_invitation(1, 'Awa Exemple', 'pending'), _invitation(2, 'Moussa Exemple', 'sent')],
      'pagination': {'current_page': 1, 'last_page': 1},
      'counts': {'invited': 2, 'pending': 1, 'sent': 1, 'opened': 0, 'confirmed': 0, 'declined': 0},
      'categories': <String>[],
      'event_ended': ended,
    };

Widget _app(Widget child) => ChangeNotifierProvider<CardProvider>(
      create: (_) => CardProvider(),
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('Reprise sur 401', () {
    Dio dioWith(_FakeApi api, Future<String?> Function() readToken) {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
      dio.httpClientAdapter = api;
      dio.interceptors.add(RetryOnUnauthorizedInterceptor(dio, readToken));
      return dio;
    }

    const unauthenticated = (401, {'message': 'Non authentifié.'});

    test('rejoue une fois avec le jeton relu depuis le stockage', () async {
      final api = _FakeApi({
        'GET /events/1/invitations': [unauthenticated, (200, {'data': []})],
      });
      final dio = dioWith(api, () async => '7|jeton-fictif');

      final response = await dio.get('/events/1/invitations');

      expect(response.statusCode, 200);
      expect(api.calls, ['GET /events/1/invitations', 'GET /events/1/invitations']);
      expect(api.authorizations.last, 'Bearer 7|jeton-fictif');
      expect(dio.options.headers['Authorization'], 'Bearer 7|jeton-fictif');
    });

    test('une seule reprise : un second 401 remonte tel quel', () async {
      final api = _FakeApi({'GET /me': [unauthenticated]});
      final dio = dioWith(api, () async => '7|jeton-fictif');

      await expectLater(dio.get('/me'), throwsA(isA<DioException>()));
      expect(api.calls.length, 2);
    });

    test('rejoue la création d’une invitation après un 401', () async {
      final api = _FakeApi({
        'POST /events/1/invitations/honor': [
          unauthenticated,
          (201, {'data': {'id': 12}})
        ],
      });
      final dio = dioWith(api, () async => '7|jeton-fictif');
      final response = await dio.post('/events/1/invitations/honor',
          data: {'name': 'Awa Exemple', 'civility': 'Mme'});
      expect(response.statusCode, 201);
      expect(api.calls.length, 2);
    });

    test('rejoue l’envoi multipart d’une photo après un 401', () async {
      final api = _FakeApi({
        'POST /events/1/invitations/12/photo': [
          unauthenticated,
          (200, {'data': {'photo_url': '/photo.webp'}})
        ],
      });
      final dio = dioWith(api, () async => '7|jeton-fictif');
      final response = await dio.post('/events/1/invitations/12/photo',
          data: FormData.fromMap({
            'photo': MultipartFile.fromBytes([1, 2, 3], filename: 'photo.png')
          }));
      expect(response.statusCode, 200);
      expect(api.calls.length, 2);
      for (final body in api.requestBodies) {
        expect(latin1.decode(body), contains('name="photo"'));
        expect(body, containsAllInOrder([1, 2, 3]));
      }
    });

    test('déconnecté (aucun jeton) ou autre 401 : pas de reprise', () async {
      final api = _FakeApi({
        'GET /me': [unauthenticated],
        'POST /auth/login': [(401, {'message': 'Identifiants invalides.'})],
      });
      await expectLater(dioWith(api, () async => null).get('/me'), throwsA(isA<DioException>()));
      await expectLater(dioWith(api, () async => '7|jeton-fictif').post('/auth/login'), throwsA(isA<DioException>()));
      expect(api.calls, ['GET /me', 'POST /auth/login']);
    });
  });

  group('Onglet Invitations', () {
    testWidgets('une erreur après chargement garde la liste et les filtres', (tester) async {
      final api = _FakeApi({
        'GET /events/1/invitations': [
          (200, _page()),
          (500, {'message': 'Le serveur a rencontré une erreur.'}),
        ],
        'GET /events/1/invitations/next': [(200, {'data': _invitation(1, 'Awa Exemple', 'pending'), 'remaining': 1})],
      });
      ApiClient.dio.httpClientAdapter = api;
      await tester.pumpWidget(_app(const Scaffold(body: EventInvitationsTab(eventId: 1, topPadding: 0))));
      await _settle(tester);
      expect(find.text('Moussa Exemple'), findsOneWidget);

      // Puce de filtre « Envoyée » (le statut de Moussa porte le même texte).
      await tester.tap(find.descendant(of: find.byType(FilterPillChip), matching: find.text('Envoyée')));
      await _settle(tester);

      expect(find.text('Le serveur a rencontré une erreur.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Moussa Exemple'), findsOneWidget);
      expect(find.descendant(of: find.byType(FilterPillChip), matching: find.text('Envoyée')), findsOneWidget);
    });

    testWidgets('événement terminé : lecture seule, aucun envoi', (tester) async {
      ApiClient.dio.httpClientAdapter = _FakeApi({
        'GET /events/1/invitations': [(200, _page(ended: true))],
        'GET /events/1/invitations/next': [(200, {'data': null, 'remaining': 0, 'event_ended': true})],
      });
      await tester.pumpWidget(_app(const Scaffold(body: EventInvitationsTab(eventId: 1, topPadding: 0))));
      await _settle(tester);

      expect(find.textContaining('Cet événement est terminé'), findsOneWidget);
      expect(find.textContaining('Envoyer au suivant'), findsNothing);
      expect(find.text('Ajouter'), findsNothing);
      expect(find.text('Envoyer'), findsNothing);
      expect(find.text('Awa Exemple'), findsOneWidget);
    });
  });

  group('Participants en direct', () {
    Map<String, dynamic> participants(int present) => {
          'participants': [
            {
              'id': 1,
              'user': {'id': 10, 'firstname': 'Awa', 'lastname': 'Exemple'},
              'checked_in_at': present > 0 ? '2026-12-11T09:05:00+00:00' : null,
            },
          ],
          'count': 1,
          'stats': {'registered': 1, 'present': present, 'not_present': 1 - present, 'walk_ins': 0},
        };

    testWidgets('actualisation silencieuse : chiffres à jour, sans loader', (tester) async {
      final api = _FakeApi({
        'GET /events/1/participants': [(200, participants(0)), (200, participants(1))],
      });
      ApiClient.dio.httpClientAdapter = api;
      await tester.pumpWidget(_app(const CompanyEventParticipantsPage(eventId: 1, eventName: 'Retrouvailles Exemple')));
      await _settle(tester);
      final presentTile = find.ancestor(of: find.text('Présents'), matching: find.byType(Column)).first;
      expect(find.descendant(of: presentTile, matching: find.text('0')), findsOneWidget);

      final state = tester.state(find.byType(CompanyEventParticipantsPage)) as SilentRefreshMixin;
      await tester.runAsync(state.silentRefreshTick);
      await tester.pump();

      expect(find.text('Chargement des participants...'), findsNothing);
      expect(find.descendant(of: presentTile, matching: find.text('1')), findsOneWidget);
      expect(api.calls.length, 2);
    });
  });

  group('Affiche', () {
    test('organisateur : l\'affiche de l\'événement est lue avec la liste', () {
      final summary = CompanyEventSummary.fromJson({'id': 1, 'name': 'Retrouvailles Exemple', 'image_url': 'https://example.test/affiche.jpg'});
      expect(summary.imageUrl, 'https://example.test/affiche.jpg');
      expect(CompanyEventSummary.fromJson({'id': 2, 'name': 'Sans affiche'}).imageUrl, isNull);
    });

    testWidgets('image entière (contain) sur fond flou (cover) de la même image', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PosterImage(imageUrl: 'https://example.test/affiche-a4.jpg')),
      ));
      final images = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).toList();
      expect(images.map((i) => i.fit), [BoxFit.cover, BoxFit.contain]);
      expect(images.map((i) => i.imageUrl).toSet(), {'https://example.test/affiche-a4.jpg'});
      expect(find.byType(ImageFiltered), findsOneWidget);
    });
  });

  group('Police du système (Android)', () {
    Future<double> scaleSeenBy(WidgetTester tester, double systemScale) async {
      late double seen;
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(systemScale)),
        child: TextScaleClamp(
          child: Builder(builder: (context) {
            seen = MediaQuery.textScalerOf(context).scale(10) / 10;
            return const SizedBox();
          }),
        ),
      ));
      return seen;
    }

    testWidgets('bornée entre 1.0 et 1.3', (tester) async {
      expect(await scaleSeenBy(tester, 2.0), closeTo(1.3, 0.001));
      expect(await scaleSeenBy(tester, 0.85), closeTo(1.0, 0.001));
      expect(await scaleSeenBy(tester, 1.15), closeTo(1.15, 0.001));
    });

    for (final scale in [1.0, 1.15, 1.3]) {
      testWidgets('la rangée de puces contient la puce à ×$scale', (tester) async {
        late double rowHeight;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Builder(builder: (context) {
                rowHeight = FilterPillChip.heightOf(context);
                return Center(
                  child: UnconstrainedBox(
                    child: FilterPillChip(label: 'Opportunités', icon: Icons.work_outline_rounded, active: false, onTap: () {}),
                  ),
                );
              }),
            ),
          ),
        ));
        final chipHeight = tester.getSize(find.byType(FilterPillChip)).height;
        expect(chipHeight, lessThanOrEqualTo(rowHeight));
        expect(rowHeight, greaterThanOrEqualTo(36));
      });
    }

    testWidgets('les carrousels grandissent avec la police, pas au-delà de 1.3', (tester) async {
      late double normal;
      late double large;
      await tester.pumpWidget(Builder(builder: (context) {
        normal = TextScaleClamp.grow(context, 236);
        return const SizedBox();
      }));
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Builder(builder: (context) {
          large = TextScaleClamp.grow(context, 236);
          return const SizedBox();
        }),
      ));
      expect(normal, 236);
      expect(large, greaterThan(236));
    });
  });
}

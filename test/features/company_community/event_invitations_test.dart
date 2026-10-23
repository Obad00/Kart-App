// Invitations d'un événement (onglet « Invitations ») : lecture des réponses
// de l'API, envoi (WhatsApp d'abord, /send ensuite et jamais bloquant),
// partage de l'image, ajout en lot depuis les contacts, sélecteur Android
// enchaîné, et onglets réservés aux comptes qui ouvrent la page.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/company_community/models/event_invitation.dart';
import 'package:kart_app/features/company_community/services/device_contacts.dart';
import 'package:kart_app/features/company_community/services/event_invitations_service.dart';
import 'package:kart_app/features/company_community/ui/company_event_participants_page.dart';
import 'package:kart_app/features/company_community/ui/event_invitations_tab.dart';
import 'package:kart_app/features/company_community/ui/invitation_contacts_flow.dart';
import 'package:kart_app/features/company_community/ui/invitation_sender.dart';
import 'package:kart_app/features/company_community/utils/phone_display.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// Faux serveur : « METHODE /chemin » → (statut, corps JSON). Garde les appels.
class _FakeApi implements HttpClientAdapter {
  final Map<String, (int, Object?)> routes;
  final List<String> calls = [];
  final Map<String, Object?> bodies = {};

  _FakeApi(this.routes);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final key = '${options.method} ${options.uri.path.replaceFirst(RegExp(r'^.*/api'), '')}';
    calls.add(key);
    bodies[key] = options.data;
    final (status, body) = routes[key] ?? (404, {'message': 'absent'});
    if (body is List<int>) {
      return ResponseBody.fromBytes(body, status, headers: {Headers.contentTypeHeader: ['image/png']});
    }
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _invitation(int id, String status, {bool reminder = false}) => {
      'id': id,
      'name': 'Awa Exemple Diallo',
      'first_name': 'Awa',
      'last_name': 'Exemple Diallo',
      'phone': '+221770000001',
      'category': 'VIP',
      'status': status,
      'needs_reminder': reminder,
      'message': 'Bonjour Awa,\n\nhttps://kart.business/i/AbCdEfGh1234',
      'whatsapp_url': 'https://wa.me/221770000001?text=Bonjour%20Awa',
    };

Map<String, (int, Object?)> _listRoutes({List<Map<String, dynamic>>? data}) => {
      'GET /events/1/invitations': (
        200,
        {
          'data': data ?? [_invitation(1, 'pending'), _invitation(2, 'sent', reminder: true)],
          'pagination': {'current_page': 1, 'last_page': 1},
          'counts': {'invited': 2, 'pending': 1, 'sent': 1, 'opened': 0, 'confirmed': 0, 'declined': 0},
          'categories': ['VIP'],
        }
      ),
      'GET /events/1/invitations/next': (200, {'data': _invitation(1, 'pending'), 'remaining': 1}),
      'POST /events/1/invitations/1/send': (200, {}),
      'POST /events/1/invitations/2/send': (200, {}),
    };

_FakeApi _useApi(Map<String, (int, Object?)> routes) {
  final api = _FakeApi(routes);
  ApiClient.dio.httpClientAdapter = api;
  return api;
}

Widget _app(Widget child) => ChangeNotifierProvider<CardProvider>(
      create: (_) => CardProvider(),
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );

/// Laisse passer les réponses simulées (vrais Future) entre deux images.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _FakeContacts implements DeviceContactsSource {
  final List<DeviceContact?> queue;
  int pickCalls = 0;

  _FakeContacts(this.queue);

  @override
  Future<DeviceContact?> pickOneNative() async {
    pickCalls++;
    return queue.isEmpty ? null : queue.removeAt(0);
  }

  @override
  Future<ContactsAccess> check() async => ContactsAccess.denied;
  @override
  Future<ContactsAccess> request() async => ContactsAccess.denied;
  @override
  Future<List<DeviceContact>> readAll() async => [];
  @override
  Future<List<DeviceContact>> pickMultipleNative() async => [];
  @override
  Future<void> openSettings() async {}
}

DeviceContact _contact(String id, String name, String number) => DeviceContact(
      id: id,
      name: name,
      phones: [DeviceContactPhone(number: number, label: 'Mobile', isMobile: true)],
    );

void main() {
  group('Réponses de l\'API', () {
    test('une invitation garde le lien wa.me et le message du backend', () {
      final invitation = EventInvitation.fromJson(_invitation(1, 'opened', reminder: true));
      expect(invitation.status, InvitationStatus.opened);
      expect(invitation.status.label, 'Ouverte');
      expect(invitation.needsReminder, isTrue);
      expect(invitation.whatsappUrl, 'https://wa.me/221770000001?text=Bonjour%20Awa');
      expect(invitation.initials, 'AE');
    });

    test('le rapport d\'ajout liste les invalides avec leur nom', () {
      final report = InvitationReport.fromJson({
        'created': 2,
        'duplicates': 1,
        'invalid': [
          {'line': 3, 'name': 'Ibrahima Exemple', 'reason': 'Téléphone invalide.'},
        ],
      });
      expect(report.created, 2);
      expect(report.duplicates, 1);
      expect(report.invalid.single.name, 'Ibrahima Exemple');
      expect(report.invalid.single.reason, 'Téléphone invalide.');
    });
  });

  group('Affichage des numéros', () {
    test('comme le site : +221 77 000 01 01, sans toucher aux autres', () {
      expect(formatPhoneForDisplay('+221770000101'), '+221 77 000 01 01');
      expect(formatPhoneForDisplay('77 000-01.31'), '+221 77 000 01 31');
      expect(formatPhoneForDisplay('00221 33 800 00 00'), '+221 33 800 00 00');
      expect(formatPhoneForDisplay('+33 6 00 00 01 34'), '+33 6 00 00 01 34');
      expect(formatPhoneForDisplay('+2250700000134'), '+2250700000134');
    });
  });

  group('Ajout en lot', () {
    test('une seule requête, numéros tels qu\'enregistrés dans le téléphone', () async {
      final api = _useApi({
        'POST /events/1/invitations/batch': (200, {'created': 2, 'duplicates': 0, 'invalid': []}),
      });
      final report = await EventInvitationsService().batch(
        1,
        [(name: 'Awa Exemple', phone: '+221 77 000 00 01'), (name: 'Moussa Exemple', phone: '77-000-00-02')],
        category: ' Partenaires ',
      );
      expect(report.created, 2);
      expect(api.calls, ['POST /events/1/invitations/batch']);
      expect(api.bodies['POST /events/1/invitations/batch'], {
        'invitations': [
          {'name': 'Awa Exemple', 'phone': '+221 77 000 00 01'},
          {'name': 'Moussa Exemple', 'phone': '77-000-00-02'},
        ],
        'category': 'Partenaires',
      });
    });
  });

  group('Envoi', () {
    testWidgets('WhatsApp s\'ouvre avec le lien du backend, puis /send', (tester) async {
      final api = _useApi(_listRoutes());
      final opened = <Uri>[];
      late BuildContext context;
      await tester.pumpWidget(_app(Builder(builder: (c) { context = c; return const SizedBox(); })));
      final sender = InvitationSender(
        service: EventInvitationsService(),
        eventId: 1,
        openExternal: (uri) async {
          opened.add(uri);
          return true;
        },
      );

      final ok = await tester.runAsync(() => sender.sendWhatsApp(context, EventInvitation.fromJson(_invitation(1, 'pending'))));
      expect(ok, isTrue);
      expect(opened.single.toString(), 'https://wa.me/221770000001?text=Bonjour%20Awa');
      expect(api.calls, ['POST /events/1/invitations/1/send']);
    });

    testWidgets('si /send échoue, l\'envoi n\'est pas bloqué', (tester) async {
      _useApi({'POST /events/1/invitations/1/send': (500, {'message': 'erreur'})});
      late BuildContext context;
      await tester.pumpWidget(_app(Scaffold(body: Builder(builder: (c) { context = c; return const SizedBox(); }))));
      final sender = InvitationSender(service: EventInvitationsService(), eventId: 1, openExternal: (_) async => true);

      final ok = await tester.runAsync(() => sender.sendWhatsApp(context, EventInvitation.fromJson(_invitation(1, 'pending'))));
      expect(ok, isTrue);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('un partage annulé ne compte pas comme envoyé', (tester) async {
      final api = _useApi({'GET /events/1/invitations/1/image.png': (200, List<int>.filled(8, 1))});
      late BuildContext context;
      await tester.pumpWidget(_app(Builder(builder: (c) { context = c; return const SizedBox(); })));
      ShareParams? shared;
      final sender = InvitationSender(
        service: EventInvitationsService(),
        eventId: 1,
        share: (params) async {
          shared = params;
          return ShareResultStatus.dismissed;
        },
        tempDir: () => Directory.systemTemp.createTemp('kart-test'),
      );

      await tester.runAsync(() => sender.shareInvitation(context, EventInvitation.fromJson(_invitation(1, 'pending'))));
      expect(shared?.text, startsWith('Bonjour Awa'));
      expect(shared?.files?.single.mimeType, 'image/png');
      expect(api.calls, ['GET /events/1/invitations/1/image.png']);
    });

    testWidgets('un partage réussi met le statut à jour', (tester) async {
      final api = _useApi({
        'GET /events/1/invitations/1/image.png': (200, List<int>.filled(8, 1)),
        'POST /events/1/invitations/1/send': (200, {}),
      });
      late BuildContext context;
      await tester.pumpWidget(_app(Builder(builder: (c) { context = c; return const SizedBox(); })));
      final sender = InvitationSender(
        service: EventInvitationsService(),
        eventId: 1,
        share: (_) async => ShareResultStatus.success,
        tempDir: () => Directory.systemTemp.createTemp('kart-test'),
      );

      await tester.runAsync(() => sender.shareInvitation(context, EventInvitation.fromJson(_invitation(1, 'pending'))));
      expect(api.calls, ['GET /events/1/invitations/1/image.png', 'POST /events/1/invitations/1/send']);
    });
  });

  group('Sélecteur Android enchaîné', () {
    testWidgets('se rouvre après chaque contact, Retour termine, sans doublon', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(_app(Builder(builder: (c) { context = c; return const SizedBox(); })));
      final source = _FakeContacts([
        _contact('a', 'Awa Exemple', '77 000 00 01'),
        _contact('b', 'Moussa Exemple', '77 000 00 02'),
        _contact('a', 'Awa Exemple', '77 000 00 01'),
        null, // Retour
        _contact('c', 'Jamais choisi', '77 000 00 03'),
      ]);

      final picked = await tester.runAsync(() => pickContactsOneByOne(context, source));
      expect(picked!.map((c) => c.name), ['Awa Exemple', 'Moussa Exemple']);
      expect(source.pickCalls, 4);
    });
  });

  group('Onglet Invitations', () {
    testWidgets('compteurs, envoi au suivant et actions par statut', (tester) async {
      _useApi(_listRoutes());
      final opened = <Uri>[];
      final service = EventInvitationsService();
      await tester.pumpWidget(_app(Scaffold(
        body: EventInvitationsTab(
          eventId: 1,
          topPadding: 0,
          service: service,
          sender: InvitationSender(
            service: service,
            eventId: 1,
            openExternal: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      )));
      await _settle(tester);

      expect(find.text('Envoyer au suivant (1)'), findsOneWidget);
      expect(find.text('Prochain : Awa Exemple Diallo'), findsOneWidget);
      expect(find.text('Envoyer'), findsOneWidget); // à envoyer
      expect(find.text('Relancer'), findsOneWidget); // 48 h sans réponse
      expect(find.text('Confirmées'), findsOneWidget);

      await tester.tap(find.text('Envoyer au suivant (1)'));
      await _settle(tester);
      expect(opened.single.toString(), 'https://wa.me/221770000001?text=Bonjour%20Awa');
    });
  });

  group('Page de l\'événement', () {
    Map<String, (int, Object?)> participants() => {
          'GET /events/1/participants': (200, {'participants': [], 'count': 0, 'stats': {}}),
        };

    testWidgets('sans accès aux invitations : l\'écran des participants d\'avant', (tester) async {
      _useApi(participants());
      await tester.pumpWidget(_app(const CompanyEventParticipantsPage(eventId: 1, eventName: 'Salon Exemple')));
      await _settle(tester);
      expect(find.text('Invitations'), findsNothing);
      expect(find.text('Inscrits'), findsOneWidget);
    });

    testWidgets('avec accès : onglets Participants et Invitations', (tester) async {
      final api = _useApi({...participants(), ..._listRoutes()});
      await tester.pumpWidget(_app(
          const CompanyEventParticipantsPage(eventId: 1, eventName: 'Salon Exemple', showInvitations: true)));
      await _settle(tester);
      expect(find.text('Participants'), findsOneWidget);
      // L'onglet Invitations n'est chargé qu'à son ouverture.
      expect(api.calls.where((c) => c.contains('invitations')), isEmpty);

      await tester.tap(find.text('Invitations'));
      await _settle(tester);
      expect(api.calls, contains('GET /events/1/invitations'));
      expect(find.text('Envoyer au suivant (1)'), findsOneWidget);
    });
  });
}

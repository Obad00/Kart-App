// Lot E2 : catégorie choisie dans une liste (avec « Nouvelle catégorie… »),
// numéro de stand pour les exposants, QR de l'événement en 5 modèles,
// affiche ouverte en plein écran. Données fictives.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/company_community/models/event_invitation.dart';
import 'package:kart_app/features/company_community/services/event_invitations_service.dart';
import 'package:kart_app/features/company_community/ui/event_qr_models_page.dart';
import 'package:kart_app/features/company_community/widgets/invitation_category_field.dart';
import 'package:kart_app/features/company_community/widgets/invitation_sheets.dart';
import 'package:kart_app/shared/widgets/poster_image.dart';

/// PNG 1 × 1 transparent.
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

class _FakeApi implements HttpClientAdapter {
  final List<String> calls = [];
  final Map<String, Object?> bodies = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path.replaceFirst(RegExp(r'^.*/api'), '');
    final key = '${options.method} $path';
    calls.add('$key?${options.uri.query}');
    bodies[key] = options.data;
    if (path.endsWith('/qr-card')) {
      return ResponseBody.fromBytes(_png, 200, headers: {Headers.contentTypeHeader: ['image/png']});
    }
    final Object body = switch (key) {
      'GET /events/1/invitations' => {
          'data': [],
          'pagination': {'current_page': 1, 'last_page': 1},
          'counts': {},
          'categories': ['Exposant', 'VIP'],
          'exhibitor_categories': ['Exposant'],
        },
      'POST /events/1/invitations' => {
          'data': {'id': 9, 'name': 'Moussa Exemple', 'phone': '+221770000002', 'status': 'pending'},
        },
      _ => {'message': 'absent'},
    };
    return ResponseBody.fromString(jsonEncode(body), body is Map && body['message'] == 'absent' ? 404 : 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _FakeApi api;
  setUp(() {
    api = _FakeApi();
    ApiClient.dio.httpClientAdapter = api;
  });

  test('lecture du numéro de stand et des catégories d\'exposants', () {
    final invitation = EventInvitation.fromJson({'id': 1, 'name': 'Moussa', 'stand_number': 'B12', 'status': 'pending'});
    expect(invitation.standNumber, 'B12');
    final page = InvitationPage.fromJson({'data': [], 'exhibitor_categories': ['Exposant']});
    expect(page.exhibitorCategories, ['Exposant']);
  });

  testWidgets('catégorie : liste existante, puis « Nouvelle catégorie… »', (tester) async {
    final controller = TextEditingController();
    final exhibitor = <bool>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: InvitationCategoryField(
          controller: controller,
          service: EventInvitationsService(),
          eventId: 1,
          onExhibitorChanged: exhibitor.add,
        ),
      ),
    ));
    await _settle(tester);

    await tester.tap(find.text('Catégorie (facultatif)'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    await tester.tap(find.text('Exposant'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Exposant');
    expect(exhibitor.last, isTrue);

    await tester.tap(find.text('Exposant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle catégorie…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Presse');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Presse');
    expect(exhibitor.last, isFalse);
  });

  testWidgets('exposant : le numéro de stand est proposé et envoyé', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showInvitationFormSheet(context, service: EventInvitationsService(), eventId: 1),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Numéro de stand (imprimé sur le badge)'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Nom complet'), 'Moussa Exemple');
    await tester.enterText(find.widgetWithText(TextField, 'Téléphone WhatsApp'), '77 000 00 02');
    await tester.tap(find.text('Catégorie (facultatif)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exposant'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Numéro de stand (imprimé sur le badge)'), 'B12');
    await tester.tap(find.text('Ajouter'));
    await _settle(tester);

    final body = api.bodies['POST /events/1/invitations'] as Map;
    expect(body['category'], 'Exposant');
    expect(body['stand_number'], 'B12');
    // Laisse le message de succès se refermer (minuteur).
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('QR de l\'événement : les 5 modèles avec aperçu, PNG et PDF', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const EventQrModelsPage(eventId: 1, eventName: 'Retrouvailles Exemple'),
    ));
    await _settle(tester);

    for (final label in ['Classique', 'Sombre', 'Couleur', 'Affiche', 'Chevalet']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('PNG'), findsNWidgets(5));
    expect(find.text('PDF'), findsNWidgets(5));
    expect(find.byType(Image), findsNWidgets(5));
    expect(api.calls.where((c) => c.contains('/qr-card?model=')).length, 5);
  });

  testWidgets('affiche : un tap ouvre le plein écran', (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PosterImage(imageUrl: 'https://example.test/affiche.jpg', onTap: () => opened++)),
    ));
    expect(find.byIcon(Icons.zoom_out_map_rounded), findsOneWidget);
    await tester.tap(find.byType(PosterImage));
    expect(opened, 1);
  });
}

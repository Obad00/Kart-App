import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kart_app/features/company_community/models/event_invitation.dart';
import 'package:kart_app/features/company_community/services/event_invitations_service.dart';
import 'package:kart_app/features/company_community/widgets/invitation_sheets.dart';

class _InvitationService extends EventInvitationsService {
  int creates = 0;
  int updates = 0;
  int uploads = 0;
  int removals = 0;
  bool existing = false;
  bool failUpload = false;

  EventInvitation invitation({String? photoUrl}) => EventInvitation(
        id: 12,
        type: 'honneur',
        name: 'Awa Exemple',
        firstName: 'Awa',
        lastName: 'Exemple',
        phone: '',
        status: InvitationStatus.pending,
        shortUrl: 'https://example.test/invitation',
        photoUrl: photoUrl,
        createdNow: !existing,
      );

  @override
  Future<Map<String, String>> honorDefaultMessages(int eventId) async => {};

  @override
  Future<EventInvitation> createHonor(int eventId,
      {required String civility,
      required String name,
      required String honorMessage,
      String? guestTitle,
      String? phone}) async {
    creates++;
    return invitation();
  }

  @override
  Future<EventInvitation> updateHonor(int eventId, int invitationId,
      {required String civility,
      required String name,
      required String honorMessage,
      String? guestTitle,
      String? phone}) async {
    updates++;
    return invitation(photoUrl: 'https://example.test/old.webp');
  }

  @override
  Future<String> uploadPhoto(
      int eventId, int invitationId, Uint8List bytes, String filename) async {
    expect(invitationId, 12);
    uploads++;
    if (failUpload) throw Exception('upload failed');
    return 'https://example.test/photo.webp';
  }

  @override
  Future<void> removePhoto(int eventId, int invitationId) async {
    expect(invitationId, 12);
    removals++;
  }
}

final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=');

Future<void> _openHonorForm(WidgetTester tester, _InvitationService service,
    {required void Function(InvitationFormResult) onResult,
    EventInvitation? invitation}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: Builder(builder: (context) {
      return TextButton(
        onPressed: () async {
          onResult(await showInvitationFormSheet(context,
              service: service,
              eventId: 1,
              invitation: invitation,
              pickPhoto: () async =>
                  XFile.fromData(_png, path: 'exemple.png')));
        },
        child: const Text('Ouvrir'),
      );
    })),
  ));
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  if (invitation == null) {
    await tester.tap(find.text('Invitation classique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invitation d’honneur').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Nom complet'), 'Awa Exemple');
  }
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('création d’honneur avec photo en thème $brightness',
        (tester) async {
      final service = _InvitationService();
      InvitationFormResult? result;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(body: Builder(builder: (context) {
          return TextButton(
            onPressed: () async {
              result = await showInvitationFormSheet(context,
                  service: service,
                  eventId: 1,
                  pickPhoto: () async =>
                      XFile.fromData(_png, path: 'exemple.png'));
            },
            child: const Text('Ouvrir'),
          );
        })),
      ));
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invitation classique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Invitation d’honneur').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Nom complet'), 'Awa Exemple');
      await tester.ensureVisible(find.text('Ajouter une photo'));
      await tester.tap(find.text('Ajouter une photo'));
      await tester.pumpAndSettle();
      expect(find.text('Remplacer'), findsOneWidget);
      await tester.ensureVisible(find.text('Ajouter').last);
      await tester.tap(find.text('Ajouter').last);
      await tester.pumpAndSettle();
      expect(service.creates, 1);
      expect(service.uploads, 1);
      expect(result?.created?.photoUrl, 'https://example.test/photo.webp');
      expect(result?.created?.shortUrl, 'https://example.test/invitation');
      await tester.pump(const Duration(seconds: 4));
    });
  }

  testWidgets('échec de photo : invitation conservée et erreur explicite',
      (tester) async {
    final service = _InvitationService()..failUpload = true;
    InvitationFormResult? result;
    await _openHonorForm(tester, service, onResult: (value) => result = value);
    await tester.ensureVisible(find.text('Ajouter une photo'));
    await tester.tap(find.text('Ajouter une photo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ajouter').last);
    await tester.tap(find.text('Ajouter').last);
    await tester.pumpAndSettle();
    expect(service.creates, 1);
    expect(service.uploads, 1);
    expect(result?.changed, isTrue);
    expect(result?.created, isNull);
    expect(find.text('Invitation créée'), findsOneWidget);
    expect(find.textContaining('La photo n’a pas pu être enregistrée'),
        findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('une invitation d’honneur existante ne voit pas sa photo écrasée',
      (tester) async {
    final service = _InvitationService()..existing = true;
    InvitationFormResult? result;
    await _openHonorForm(tester, service, onResult: (value) => result = value);
    await tester.ensureVisible(find.text('Ajouter une photo'));
    await tester.tap(find.text('Ajouter une photo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ajouter').last);
    await tester.tap(find.text('Ajouter').last);
    await tester.pumpAndSettle();
    expect(service.creates, 1);
    expect(service.uploads, 0);
    expect(result?.created?.createdNow, isFalse);
  });

  testWidgets('retrait de la photo pendant la modification', (tester) async {
    final service = _InvitationService();
    InvitationFormResult? result;
    await _openHonorForm(tester, service,
        invitation:
            service.invitation(photoUrl: 'https://example.test/old.webp'),
        onResult: (value) => result = value);
    await tester.ensureVisible(find.text('Retirer').first);
    await tester.tap(find.text('Retirer').first);
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(service.updates, 1);
    expect(service.removals, 1);
    expect(result?.changed, isTrue);
    await tester.pump(const Duration(seconds: 4));
  });
}

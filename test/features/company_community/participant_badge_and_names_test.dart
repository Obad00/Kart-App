// Liste des participants (organisateur) : un nom sur chaque ligne, jamais
// d'adresse technique, « Absent » seulement après la fin, et badge PNG/PDF
// depuis la fiche. Données fictives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/company_community/models/event_participant_summary.dart';
import 'package:kart_app/features/company_community/widgets/participant_list_widgets.dart';

void main() {
  test('nom, sinon téléphone, sinon « Participant sans nom » ; email technique masqué', () {
    final named = EventParticipantSummary.fromJson({
      'id': 1,
      'display_name': 'Awa Exemple',
      'user': {'id': 10, 'firstname': 'Awa', 'lastname': 'Exemple', 'email': 'awa@example.com'},
    });
    final phoneOnly = EventParticipantSummary.fromJson({
      'id': 2,
      'user': {'id': 11, 'firstname': '', 'lastname': '', 'phone': '+221770000001', 'email': 'visiteur-221770000001@kart-evenement.local'},
    });
    final nothing = EventParticipantSummary.fromJson({'id': 3, 'user': null, 'guest_label': null});

    expect(named.displayName, 'Awa Exemple');
    expect(named.email, 'awa@example.com');
    expect(phoneOnly.displayName, '+221770000001');
    expect(phoneOnly.email, isNull);
    expect(nothing.displayName, 'Participant sans nom');
  });

  Future<void> pumpSheet(WidgetTester tester, {required bool ended, Future<void> Function(String)? onBadge}) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: ParticipantDetailSheet(displayName: 'Moussa Exemple', isPresent: false, eventHasEnded: ended, onBadge: onBadge),
      ),
    ));
  }

  testWidgets('« Pas encore arrivé·e » pendant l\'événement, « Absent » après', (tester) async {
    await pumpSheet(tester, ended: false);
    expect(find.text('Pas encore arrivé·e'), findsOneWidget);
    expect(find.text('Absent'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await pumpSheet(tester, ended: true);
    expect(find.text('Absent'), findsOneWidget);
  });

  testWidgets('fiche organisateur : badge PNG et PDF', (tester) async {
    final formats = <String>[];
    await pumpSheet(tester, ended: false, onBadge: (format) async => formats.add(format));

    await tester.tap(find.byKey(const Key('participant-badge-png')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('participant-badge-pdf')));
    await tester.pumpAndSettle();

    expect(formats, ['png', 'pdf']);
  });
}

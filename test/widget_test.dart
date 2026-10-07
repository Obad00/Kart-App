import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/features/digital_card/widgets/card_stats_row.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_data.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_faces.dart';
import 'package:kart_app/features/digital_card/widgets/kart_flip_card.dart';

/// Tests de l'écran Carte (remplacent le test "compteur" généré par
/// `flutter create`, qui ne correspondait à aucun écran de KART).
Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('CardWeeklyStats.fromJson', () {
    test('lit une réponse complète de /me/card-stats', () {
      final stats = CardWeeklyStats.fromJson({
        'scans_this_week': 24,
        'scans_previous_week': 18,
        'new_contacts_this_week': 7,
        'new_contacts_previous_week': 9,
      });

      expect(stats, isNotNull);
      expect(stats!.scansThisWeek, 24);
      expect(stats.newContactsPreviousWeek, 9);
    });

    test('renvoie null si un champ manque (le bloc est alors masqué)', () {
      expect(
        CardWeeklyStats.fromJson({'scans_this_week': 24}),
        isNull,
      );
    });
  });

  testWidgets('la face infos n\'affiche que les coordonnées renseignées',
      (tester) async {
    const data = KartCardData(
      fullName: 'Adama Dabo',
      phone: '+221 77 000 00 00',
      email: null,
      city: '  ',
    );

    await tester.pumpWidget(
      _wrap(const KartCardInfoFace(width: 320, data: data)),
    );

    expect(find.text('+221 77 000 00 00'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline), findsNothing);
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
  });

  testWidgets('les deux faces ont exactement la même taille', (tester) async {
    const data = KartCardData(fullName: 'Adama Dabo', jobTitle: 'CEO');

    // Côte à côte : l'écran de test (800x600) ne tient pas deux faces
    // empilées.
    await tester.pumpWidget(_wrap(Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        KartCardQrFace(
          key: ValueKey('qr'),
          width: 300,
          data: data,
          qr: SizedBox.expand(),
        ),
        KartCardInfoFace(key: ValueKey('info'), width: 300, data: data),
      ],
    )));

    final qrSize = tester.getSize(find.byKey(const ValueKey('qr')));
    final infoSize = tester.getSize(find.byKey(const ValueKey('info')));
    expect(qrSize, infoSize);
    expect(qrSize.height, closeTo(300 * kartCardAspect, 0.01));
  });

  testWidgets('le bouton sous la carte indique l\'autre face', (tester) async {
    await tester.pumpWidget(
      _wrap(KartFlipButton(showingInfo: false, onTap: () {})),
    );
    expect(find.text('Afficher la carte'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(KartFlipButton(showingInfo: true, onTap: () {}), dark: true),
    );
    expect(find.text('Afficher le QR'), findsOneWidget);
  });

  testWidgets('statistiques : singulier/pluriel et flèche de tendance',
      (tester) async {
    await tester.pumpWidget(_wrap(const CardStatsRow(
      stats: CardWeeklyStats(
        scansThisWeek: 24,
        scansPreviousWeek: 18,
        newContactsThisWeek: 1,
        newContactsPreviousWeek: 0,
      ),
    )));

    expect(find.text('scans cette semaine'), findsOneWidget);
    expect(find.text('nouveau contact'), findsOneWidget);
    // Hausse sur les scans ; pas de flèche sur les contacts (aucune donnée
    // la semaine précédente).
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.trending_down_rounded), findsNothing);
    // Pas de carte NFC : aucune tuile « taps NFC ».
    expect(find.textContaining('NFC'), findsNothing);
  });

  testWidgets('statistiques : les taps NFC apparaissent à côté des scans',
      (tester) async {
    await tester.pumpWidget(_wrap(const CardStatsRow(
      stats: CardWeeklyStats(
        scansThisWeek: 24,
        scansPreviousWeek: 18,
        newContactsThisWeek: 1,
        newContactsPreviousWeek: 0,
        nfcTapsThisWeek: 5,
        nfcTapsPreviousWeek: 2,
      ),
    )));

    expect(tester.takeException(), isNull);
    expect(find.text('scans cette semaine'), findsOneWidget);
    expect(find.text('taps NFC cette semaine'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.contactless_outlined), findsOneWidget);
  });

  testWidgets('statistiques : carte NFC active, tuile affichée même à 0 tap',
      (tester) async {
    await tester.pumpWidget(_wrap(const CardStatsRow(
      stats: CardWeeklyStats(
        scansThisWeek: 4,
        scansPreviousWeek: 4,
        newContactsThisWeek: 0,
        newContactsPreviousWeek: 0,
        nfcTapsThisWeek: 0,
        nfcTapsPreviousWeek: 0,
        nfcActive: true,
      ),
    )));

    expect(find.text('tap NFC cette semaine'), findsOneWidget);
    expect(find.byIcon(Icons.contactless_outlined), findsOneWidget);
  });
}

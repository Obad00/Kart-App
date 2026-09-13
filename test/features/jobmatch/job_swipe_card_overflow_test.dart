// Reproduit le bug remonté sur petit écran : "BOTTOM OVERFLOWED BY 15
// PIXELS" dans JobSwipeCard quand l'espace vertical disponible pour la
// carte est trop réduit (en-tête + titre sur 2 lignes + salaire + chips +
// date de publication ne tiennent plus). Vérifie que le mode compact de
// job_swipe_card.dart absorbe ce manque d'espace au lieu de déborder.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/jobmatch/model/job_feed_item.dart';
import 'package:kart_app/features/jobmatch/widgets/job_swipe_card.dart';

JobFeedItem _sampleJob() {
  return JobFeedItem(
    id: 1,
    title: 'Stagiaire commercial(e)',
    companyName: 'Yello',
    isRemote: true,
    contractType: 'stage',
    score: 85,
    skills: const ['Relations sociales', 'Prospection commerciale'],
    publishedAt: DateTime.now().subtract(const Duration(days: 3)),
  );
}

Widget _wrap({required double height, required double width}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: JobSwipeCard(
            job: _sampleJob(),
            onLike: () {},
            onReject: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'JobSwipeCard ne déborde pas quand la carte est très basse (petit écran)',
    (tester) async {
      // ~300px : proche du budget vertical d'un petit téléphone une fois
      // l'en-tête (logo + badge "% Profil correspondant") déduit — c'est ce
      // qui produisait le RenderFlex overflow rapporté.
      await tester.pumpWidget(_wrap(height: 300, width: 330));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Stagiaire commercial(e)'), findsOneWidget);
      // La ligne la moins essentielle est celle qu'on sacrifie en mode
      // compact pour garder le reste lisible sans déborder.
      expect(find.textContaining('Publiée'), findsNothing);
    },
  );

  testWidgets(
    'JobSwipeCard affiche toutes les informations quand il y a assez de place',
    (tester) async {
      await tester.pumpWidget(_wrap(height: 640, width: 360));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Stagiaire commercial(e)'), findsOneWidget);
      expect(find.textContaining('Publiée'), findsOneWidget);
    },
  );
}

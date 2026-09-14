// Reproduit le bug remonté sur petit écran : "BOTTOM OVERFLOWED BY 15
// PIXELS" dans JobSwipeCard quand l'espace vertical disponible pour la
// carte est trop réduit (en-tête + titre sur 2 lignes + salaire + chips +
// date de publication ne tiennent plus).
//
// Le premier correctif (mode "compact" à un seuil de 210px, cf. historique
// git 7d072ae/18e07c3) réduisait ce risque sans l'éliminer : il ne tenait
// compte que de la hauteur d'écran, pas de la taille de texte système
// (Réglages > Affichage > Taille du texte) — cf. le cas
// "texte système agrandi" ci-dessous, qui déborde encore avec ce correctif
// (voir aussi iphone13_repro_test.dart). Le bloc d'infos utilise maintenant
// FittedBox(scaleDown) : garantie structurelle qu'il tient toujours dans
// l'espace donné, quels que soient la hauteur ou le facteur d'échelle de
// texte, plutôt qu'un seuil en pixels à réajuster à chaque signalement.
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

Widget _wrap({
  required double height,
  required double width,
  double textScale = 1.0,
}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: MaterialApp(
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
      // FittedBox rétrécit tout le bloc au lieu de sacrifier une ligne :
      // "Publiée..." reste donc toujours présente, juste plus petite.
      expect(find.textContaining('Publiée'), findsOneWidget);
    },
  );

  testWidgets(
    'JobSwipeCard ne déborde pas avec le texte système agrandi (iPhone 13, '
    'bug remonté en usage réel)',
    (tester) async {
      // Reproduit précisément le cas qui échappait au 1er correctif : une
      // hauteur de carte réaliste sur iPhone 13 (cf. iphone13_repro_test.dart
      // — ~340px, tout juste suffisant à taille de texte par défaut) combinée
      // à un réglage de taille de texte système légèrement supérieur au
      // défaut (1.3 — un cran "Plus grand" tout à fait courant, pas un
      // réglage d'accessibilité extrême).
      await tester.pumpWidget(
        _wrap(height: 340, width: 390, textScale: 1.3),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Stagiaire commercial(e)'), findsOneWidget);
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

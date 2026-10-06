// Remonté par un client (CMAS) : son logo horizontal était coupé sur la
// carte, au point qu'il y renonçait (la carte affichait l'initiale « C »).
// Le logo entier (`logo_full`) est maintenant affiché en BoxFit.contain,
// dans une pastille claire s'il est opaque. Ces tests vérifient que :
//  - un logo horizontal est entier (ratio conservé), sans débordement ;
//  - un logo opaque a sa pastille, un logo détouré non ;
//  - une carte sans logo entier (ancien logo, photo) garde sa tuile carrée.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_data.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_faces.dart';

const double _cardWidth = 330;
const double _tile = 34; // hauteur du logo à la largeur de référence

/// PNG uni de la taille demandée, fabriqué sans réseau ni fichier.
Future<MemoryImage> _logo(WidgetTester tester, int width, int height) async {
  final Uint8List bytes = (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFF0B2B5B),
    );
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }))!;
  return MemoryImage(bytes);
}

Future<void> _pumpCard(WidgetTester tester, KartCardData data) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: KartCardQrFace(
            width: _cardWidth,
            data: data,
            qr: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );
  // Le décodage d'une image est asynchrone : on l'attend, puis on
  // reconstruit pour que la carte prenne ses dimensions réelles.
  final image = data.logoFullImage;
  if (image != null) {
    final context = tester.element(find.byType(KartCardQrFace));
    await tester.runAsync(() => precacheImage(image, context));
  }
  await tester.pumpAndSettle();
}

/// L'image du logo entier, s'il y en a une sur la carte.
Finder _fullLogoImage() => find.byWidgetPredicate(
      (w) => w is Image && w.fit == BoxFit.contain,
    );

/// La pastille claire posée derrière un logo opaque.
Finder _pill() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == const Color(0xFFF7F5F0),
    );

void main() {
  testWidgets('un logo horizontal est affiché en entier, sans débordement',
      (tester) async {
    await _pumpCard(
      tester,
      KartCardData(
        fullName: 'Ndeye Fatou Cissé',
        brandName: 'Cabinet Médical Ahmadina Saliou (CMAS)',
        logoUrl: 'https://exemple.test/logo.png',
        logoFullUrl: 'https://exemple.test/logo_full.png',
        logoTransparent: false,
        logoFullImage: await _logo(tester, 400, 100), // ratio 4:1
      ),
    );

    expect(tester.takeException(), isNull);

    // Pastille : hauteur de la tuile, largeur plafonnée à 2,6 × la hauteur.
    final pill = tester.getSize(_pill());
    expect(pill.height, moreOrLessEquals(_tile, epsilon: 0.5));
    expect(pill.width, lessThanOrEqualTo(_tile * 2.6 + 0.5));
    expect(pill.width, greaterThan(_tile * 2));

    // Le logo tient en entier dans la pastille (contain) : jamais coupé.
    final image = tester.widget<Image>(_fullLogoImage());
    expect(image.fit, BoxFit.contain);
    final imageBox = tester.getRect(_fullLogoImage());
    expect(tester.getRect(_pill()).contains(imageBox.topLeft), isTrue);
    expect(tester.getRect(_pill()).contains(imageBox.bottomRight), isTrue);

    // Le nom de l'entreprise reste visible à côté.
    expect(find.textContaining('CABINET MÉDICAL'), findsOneWidget);
  });

  testWidgets('un logo carré opaque garde une pastille carrée', (tester) async {
    await _pumpCard(
      tester,
      KartCardData(
        fullName: 'Awa Diop',
        logoUrl: 'https://exemple.test/logo.png',
        logoFullUrl: 'https://exemple.test/logo_full.png',
        logoTransparent: false,
        logoFullImage: await _logo(tester, 200, 200),
      ),
    );

    expect(tester.takeException(), isNull);
    final pill = tester.getSize(_pill());
    expect(pill.width, moreOrLessEquals(_tile, epsilon: 0.5));
    expect(pill.height, moreOrLessEquals(_tile, epsilon: 0.5));
  });

  testWidgets('un logo vertical ne dépasse pas la hauteur de la tuile',
      (tester) async {
    await _pumpCard(
      tester,
      KartCardData(
        fullName: 'Awa Diop',
        logoUrl: 'https://exemple.test/logo.png',
        logoFullUrl: 'https://exemple.test/logo_full.png',
        logoTransparent: false,
        logoFullImage: await _logo(tester, 100, 400),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(_pill()).height, moreOrLessEquals(_tile, epsilon: 0.5));
    expect(tester.getSize(_fullLogoImage()).height, lessThanOrEqualTo(_tile));
  });

  testWidgets('un logo détouré est posé sans pastille', (tester) async {
    await _pumpCard(
      tester,
      KartCardData(
        fullName: 'Awa Diop',
        logoUrl: 'https://exemple.test/logo.png',
        logoFullUrl: 'https://exemple.test/logo_full.png',
        logoTransparent: true,
        logoFullImage: await _logo(tester, 400, 100),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_pill(), findsNothing);
    expect(_fullLogoImage(), findsOneWidget);
  });

  testWidgets('sans logo entier, la carte garde sa tuile carrée habituelle',
      (tester) async {
    // Ancien logo (envoyé avant ce traitement) ou aucun logo : rien ne change.
    await _pumpCard(
      tester,
      const KartCardData(fullName: 'Awa Diop', brandName: 'Exemple SARL'),
    );

    expect(tester.takeException(), isNull);
    expect(_pill(), findsNothing);
    expect(_fullLogoImage(), findsNothing);
    expect(find.text('E'), findsOneWidget); // initiale dans la tuile
  });

  testWidgets('la photo de profil en repli reste ronde, sans pastille',
      (tester) async {
    await _pumpCard(
      tester,
      KartCardData(
        fullName: 'Awa Diop',
        logoIsPhoto: true,
        // Même si un logo entier était fourni par erreur, une photo n'est
        // jamais traitée comme un logo.
        logoFullUrl: 'https://exemple.test/logo_full.png',
        logoFullImage: await _logo(tester, 400, 100),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_pill(), findsNothing);
    expect(_fullLogoImage(), findsNothing);
  });
}

// Remonté par un client : « Cabinet Médical Ahmadina Saliou (CMAS) » était
// coupé sur la carte (« …SALIO… ») et sur le profil (« …(CMA… »).
//  - Carte, disposition A : le nom reste à côté du logo, sur 3 lignes au
//    plus ; il est réduit avant d'être coupé.
//  - Carte, disposition B (repli automatique) : s'il ne tient pas à côté du
//    logo même à la taille minimale, il passe sur sa propre ligne, pleine
//    largeur, sur 2 lignes. Jamais de « … » tant que A ou B suffit.
//  - Profil : 2 lignes au lieu d'une.
// Rendu avec la vraie police de l'app (Syne) : avec la police de test par
// défaut, les largeurs ne voudraient rien dire.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_data.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_faces.dart';
import 'package:kart_app/features/profile/widgets/profile_company_name.dart';
import 'package:kart_app/shared/widgets/shrink_to_fit_text.dart';

const _cmas = 'Cabinet Médical Ahmadina Saliou (CMAS)';

/// Nettement plus long que le nom du CMAS : ne tient pas en 3 lignes à côté
/// d'un logo horizontal, même à la taille minimale.
const _veryLong =
    'Compagnie Sénégalaise de Transport et de Logistique Portuaire';

/// Le logo entier (image en BoxFit.contain) affiché sur la carte.
Finder _logoImage() =>
    find.byWidgetPredicate((w) => w is Image && w.fit == BoxFit.contain);

/// Logo horizontal 4:1, fabriqué sans réseau.
Future<MemoryImage> _wideLogo(WidgetTester tester) async {
  final Uint8List bytes = (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 400, 100),
      Paint()..color = const Color(0xFF0B2B5B),
    );
    final image = await recorder.endRecording().toImage(400, 100);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }))!;
  return MemoryImage(bytes);
}

Future<void> _pumpCard(
  WidgetTester tester,
  KartCardData data, {
  bool infoFace = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: infoFace
              ? KartCardInfoFace(width: 330, data: data)
              : KartCardQrFace(
                  width: 330,
                  data: data,
                  qr: const SizedBox.expand(),
                ),
        ),
      ),
    ),
  );
  // ignore: invalid_use_of_visible_for_testing_member
  final image = data.logoFullImage;
  if (image != null) {
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() => precacheImage(image, context));
  }
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

void main() {
  setUpAll(() async {
    final font = File('assets/fonts/Syne.ttf').readAsBytesSync();
    final loader = FontLoader('Syne')
      ..addFont(Future.value(ByteData.view(font.buffer)));
    await loader.load();
  });

  group('carte', () {
    testWidgets('le nom CMAS est entier à côté du logo horizontal',
        (tester) async {
      final logo = await _wideLogo(tester);
      await _pumpCard(
        tester,
        KartCardData(
          fullName: 'Ndeye Fatou Cissé',
          jobTitle: 'Médecin du travail',
          brandName: _cmas,
          logoUrl: 'https://exemple.test/logo.png',
          logoFullUrl: 'https://exemple.test/logo_full.png',
          logoTransparent: false,
          logoFullImage: logo,
        ),
      );

      expect(tester.takeException(), isNull);
      final name = _paragraph(tester, _cmas.toUpperCase());
      expect(name.didExceedMaxLines, isFalse, reason: 'nom coupé par « … »');
      // Réduit pour tenir, mais jamais sous le minimum lisible.
      expect(name.text.style!.fontSize, greaterThanOrEqualTo(9));
      expect(find.text('KART'), findsOneWidget);
    });

    testWidgets('le nom CMAS est entier sans logo, à sa taille normale',
        (tester) async {
      await _pumpCard(
        tester,
        const KartCardData(fullName: 'Ndeye Fatou Cissé', brandName: _cmas),
      );

      expect(tester.takeException(), isNull);
      final name = _paragraph(tester, _cmas.toUpperCase());
      expect(name.didExceedMaxLines, isFalse);
      expect(name.text.style!.fontSize, 11.5);
    });

    testWidgets('même résultat sur la face infos', (tester) async {
      final logo = await _wideLogo(tester);
      await _pumpCard(
        tester,
        KartCardData(
          fullName: 'Ndeye Fatou Cissé',
          brandName: _cmas,
          phone: '+221770000000',
          email: 'contact@exemple.test',
          logoUrl: 'https://exemple.test/logo.png',
          logoFullUrl: 'https://exemple.test/logo_full.png',
          logoTransparent: false,
          logoFullImage: logo,
        ),
        infoFace: true,
      );

      expect(tester.takeException(), isNull);
      expect(_paragraph(tester, _cmas.toUpperCase()).didExceedMaxLines, isFalse);
    });

    testWidgets('le nom CMAS reste à côté du logo (disposition A)',
        (tester) async {
      final logo = await _wideLogo(tester);
      await _pumpCard(
        tester,
        KartCardData(
          fullName: 'Ndeye Fatou Cissé',
          brandName: _cmas,
          logoUrl: 'https://exemple.test/logo.png',
          logoFullUrl: 'https://exemple.test/logo_full.png',
          logoTransparent: false,
          logoFullImage: logo,
        ),
      );

      final name = tester.getRect(find.text(_cmas.toUpperCase()));
      final logoBox = tester.getRect(_logoImage());
      expect(name.left, greaterThan(logoBox.right), reason: 'à droite du logo');
      expect(name.top, lessThan(logoBox.bottom), reason: 'sur la même ligne');
    });

    testWidgets(
        'un nom bien plus long avec un logo horizontal bascule en disposition B',
        (tester) async {
      final logo = await _wideLogo(tester);
      await _pumpCard(
        tester,
        KartCardData(
          fullName: 'Ndeye Fatou Cissé',
          jobTitle: 'Directrice générale',
          brandName: _veryLong,
          logoUrl: 'https://exemple.test/logo.png',
          logoFullUrl: 'https://exemple.test/logo_full.png',
          logoTransparent: false,
          logoFullImage: logo,
        ),
      );

      expect(tester.takeException(), isNull);

      // Pas de troncature : le nom est entier.
      final paragraph = _paragraph(tester, _veryLong.toUpperCase());
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'nom coupé par « … »');
      expect(paragraph.text.style!.fontSize, greaterThanOrEqualTo(9));

      // Disposition B : le nom est SOUS le logo, aligné à gauche avec lui,
      // sur la largeur utile de la carte (282 = 330 − 2 × 24 de marge) et
      // non plus sur la centaine de pixels restant à côté du logo.
      final name = tester.getRect(find.text(_veryLong.toUpperCase()));
      final logoBox = tester.getRect(_logoImage());
      expect(name.top, greaterThanOrEqualTo(logoBox.bottom));
      expect(name.left, lessThan(logoBox.right));
      expect(name.width, greaterThan(200));
      expect(name.width, lessThanOrEqualTo(282));

      // « KART » reste sur la ligne du logo.
      final kart = tester.getRect(find.text('KART'));
      expect(kart.center.dy, closeTo(logoBox.center.dy, 6));
    });

    testWidgets('la disposition B tient aussi sur la face infos',
        (tester) async {
      final logo = await _wideLogo(tester);
      await _pumpCard(
        tester,
        KartCardData(
          fullName: 'Ndeye Fatou Cissé',
          jobTitle: 'Directrice générale',
          brandName: _veryLong,
          phone: '+221770000000',
          email: 'contact@exemple.test',
          city: 'Dakar',
          logoUrl: 'https://exemple.test/logo.png',
          logoFullUrl: 'https://exemple.test/logo_full.png',
          logoTransparent: false,
          logoFullImage: logo,
        ),
        infoFace: true,
      );

      expect(tester.takeException(), isNull); // aucun débordement
      expect(
        _paragraph(tester, _veryLong.toUpperCase()).didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('sans logo, le même nom très long reste à côté de la tuile',
        (tester) async {
      // La tuile carrée laisse assez de place : pas besoin du repli.
      await _pumpCard(
        tester,
        const KartCardData(fullName: 'Awa Diop', brandName: _veryLong),
      );

      expect(tester.takeException(), isNull);
      final paragraph = _paragraph(tester, _veryLong.toUpperCase());
      expect(paragraph.didExceedMaxLines, isFalse);
      final kart = tester.getRect(find.text('KART'));
      final name = tester.getRect(find.text(_veryLong.toUpperCase()));
      expect(name.right, lessThan(kart.left)); // même ligne que « KART »
      expect((name.center.dy - kart.center.dy).abs(), lessThan(20));
    });

    testWidgets('un nom court garde sa taille et tient sur une ligne',
        (tester) async {
      await _pumpCard(
        tester,
        const KartCardData(fullName: 'Awa Diop', brandName: 'Yello'),
      );

      final name = _paragraph(tester, 'YELLO');
      expect(name.text.style!.fontSize, 11.5);
      expect(name.didExceedMaxLines, isFalse);
    });
  });

  group('ShrinkToFitText', () {
    Future<RenderParagraph> pump(WidgetTester tester, double width) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const ShrinkToFitText(
                  'CABINET MÉDICAL AHMADINA SALIOU (CMAS)',
                  maxLines: 2,
                  minFontSize: 9,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.renderObject<RenderParagraph>(find.byType(RichText));
    }

    testWidgets('garde la taille normale quand le texte tient', (tester) async {
      final paragraph = await pump(tester, 400);
      expect(paragraph.text.style!.fontSize, 12);
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('réduit la taille avant de couper', (tester) async {
      final paragraph = await pump(tester, 140);
      expect(paragraph.text.style!.fontSize, lessThan(12));
      expect(paragraph.text.style!.fontSize, greaterThanOrEqualTo(9));
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('ne coupe qu\'en dernier recours, à la taille minimale',
        (tester) async {
      final paragraph = await pump(tester, 60);
      expect(paragraph.text.style!.fontSize, 9);
      expect(paragraph.didExceedMaxLines, isTrue);
    });
  });

  group('profil', () {
    testWidgets('le nom CMAS est entier sur un petit écran', (tester) async {
      // Largeur disponible à côté de la photo sur un iPhone SE (320 pt).
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(width: 200, child: ProfileCompanyName(_cmas)),
            ),
          ),
        ),
      );

      final name = _paragraph(tester, _cmas);
      expect(name.didExceedMaxLines, isFalse, reason: 'nom coupé par « … »');
      // Sur une seule ligne (l'ancien réglage), il ne tenait pas.
      expect(name.size.height, greaterThan(13 * 1.2));
    });
  });
}

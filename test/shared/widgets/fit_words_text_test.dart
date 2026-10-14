import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/public_card_settings/models/public_card_settings.dart';
import 'package:kart_app/features/public_card_settings/widgets/public_card_thumbnail.dart';
import 'package:kart_app/shared/widgets/fit_words_text.dart';

/// Noms fictifs, de la forme de ceux qui se coupaient.
const _names = [
  'Abdoulaye Exemple',
  'Aminata Fatou Ndiaye',
  'Mouhamadou Moustapha Exemple Sy',
  'Mouhamadoulamine',
];

/// Chaque mot du nom tient sur une ligne, à la taille rendue.
void _expectNoWordSplit(WidgetTester tester, Finder paragraph, String name) {
  final render = tester.renderObject<RenderParagraph>(paragraph);
  final style = render.text.style!;
  for (final word in name.split(' ')) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(painter.width, lessThanOrEqualTo(render.size.width + 0.5),
        reason: '« $word » à ${style.fontSize} px dans ${render.size.width} px');
    painter.dispose();
  }
}

void main() {
  // Vraies polices : la police de test par défaut dessine chaque lettre
  // en carré, bien plus large que Syne, et fausserait les largeurs.
  setUpAll(() async {
    for (final font in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
      final bytes = File(font.value).readAsBytesSync();
      await (FontLoader(font.key)..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
    }
  });

  testWidgets('un mot trop long fait baisser la taille, sans passer sous le minimum',
      (tester) async {
    const style = TextStyle(fontFamily: 'Syne', fontSize: 40, fontWeight: FontWeight.w800);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 260,
          child: FitWordsText('Mouhamadoulamine', style: style, minFontSize: 12),
        ),
      ),
    ));

    final render = tester.renderObject<RenderParagraph>(find.byType(RichText));
    expect(render.text.style!.fontSize, lessThan(40));
    expect(render.text.style!.fontSize, greaterThanOrEqualTo(12));
    _expectNoWordSplit(tester, find.byType(RichText), 'Mouhamadoulamine');
  });

  testWidgets('un nom qui tient garde sa taille normale', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 400,
          child: FitWordsText('Awa Diop', style: TextStyle(fontFamily: 'Syne', fontSize: 28)),
        ),
      ),
    ));

    expect(tester.renderObject<RenderParagraph>(find.byType(RichText)).text.style!.fontSize, 28);
  });

  // Aperçu de « Ma carte publique », cinq dispositions, téléphones étroits.
  for (final width in [320.0, 375.0, 390.0]) {
    for (final layout in PublicCardSettings.layouts) {
      testWidgets('aperçu $layout à ${width.toInt()} px : aucun mot coupé',
          (tester) async {
        tester.view.physicalSize = Size(width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        for (final name in _names) {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  // Largeur réelle de l'aperçu : écran moins les marges.
                  width: width - 32,
                  child: PublicCardLivePreview(
                    settings: PublicCardSettings(layout: layout),
                    accent: EffectiveAccent.fallback,
                    identity: PreviewIdentity(fullName: name),
                  ),
                ),
              ),
            ),
          ));

          final names = find.descendant(
            of: find.byType(FitWordsText),
            matching: find.byType(RichText),
          );
          expect(names, findsWidgets);
          for (final element in names.evaluate()) {
            final text = (element.widget as RichText).text.toPlainText();
            _expectNoWordSplit(tester, find.byWidget(element.widget), text);
          }
        }
      });
    }
  }
}

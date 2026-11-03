// Écran de transition « Email vérifié » : centré, aucun texte coupé (police
// normale et ×1,3, petit écran), au moins 2 secondes. Données fictives.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/widgets/email_verified_transition.dart';

Future<void> _pump(WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
      child: const Scaffold(body: SafeArea(child: EmailVerifiedTransition())),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectWholeAndCentered(WidgetTester tester, String text, Size size) {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  expect(paragraph.didExceedMaxLines, isFalse, reason: '« $text » coupé');
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect((rect.center.dx - size.width / 2).abs(), lessThan(2), reason: '« $text » décentré');
}

void main() {
  setUpAll(() async {
    for (final f in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
      await (FontLoader(f.key)..addFont(Future.value(ByteData.view(File(f.value).readAsBytesSync().buffer)))).load();
    }
  });

  for (final (label, size, scale) in [
    ('taille normale', const Size(390, 844), 1.0),
    ('grande police ×1,3', const Size(390, 844), 1.3),
    ('petit écran, grande police', const Size(320, 568), 1.3),
  ]) {
    testWidgets('tout centré, rien de coupé : $label', (tester) async {
      await _pump(tester, size, scale);

      expect(tester.takeException(), isNull);
      _expectWholeAndCentered(tester, 'Email vérifié', size);
      _expectWholeAndCentered(tester, 'Création de votre carte digitale…', size);
      final icon = tester.getCenter(find.byIcon(Icons.mark_email_read_rounded));
      expect((icon.dx - size.width / 2).abs(), lessThan(2));
      await tester.pumpWidget(const SizedBox());
    });
  }

  test('au moins 2 secondes, même si la carte est créée plus vite', () async {
    final waited = <Duration>[];
    final fast = Stopwatch()..start();
    await EmailVerifiedTransition.waitRemaining(fast, delay: (d) async => waited.add(d));
    expect(waited.single, greaterThan(const Duration(milliseconds: 1900)));

    waited.clear();
    final slow = _ElapsedStopwatch(const Duration(seconds: 3));
    await EmailVerifiedTransition.waitRemaining(slow, delay: (d) async => waited.add(d));
    expect(waited, isEmpty);
  });
}

class _ElapsedStopwatch extends Stopwatch {
  _ElapsedStopwatch(this._elapsed);
  final Duration _elapsed;
  @override
  Duration get elapsed => _elapsed;
}

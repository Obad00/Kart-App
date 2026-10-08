// Face infos de la carte : identique à celle d'origine, sauf deux choses —
// les contacts sont remontés sous le titre, et le bouton « Personnaliser ma
// carte » occupe le bas.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_data.dart';
import 'package:kart_app/features/digital_card/widgets/kart_card_faces.dart';

Future<void> _pump(
  WidgetTester tester,
  KartCardData data, {
  double width = 281,
  VoidCallback? onCustomize,
}) =>
    tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Center(
          child: KartCardInfoFace(
            width: width,
            data: data,
            onCustomize: onCustomize,
          ),
        ),
      ),
    ));

const _full = KartCardData(
  fullName: 'Adama Dabo',
  jobTitle: 'Tech entrepreneur',
  brandName: 'Sankora Group',
  phone: '+221 77 000 00 00',
  email: 'adama@sankoragroup.com',
  city: 'Dakar, Sénégal',
);

void main() {
  setUpAll(() async {
    final bytes = File('assets/fonts/Syne.ttf').readAsBytesSync();
    await (FontLoader('Syne')..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });

  testWidgets('même contenu qu\'avant : entreprise, KART, nom, titre, contacts',
      (tester) async {
    await _pump(tester, _full, onCustomize: () {});

    for (final text in [
      'SANKORA GROUP', 'KART', 'Adama Dabo', 'TECH ENTREPRENEUR', //
      '+221 77 000 00 00', 'adama@sankoragroup.com', 'Dakar, Sénégal',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });

  testWidgets('les contacts sont juste sous le titre, le bouton tout en bas',
      (tester) async {
    await _pump(tester, _full, onCustomize: () {});

    final card = tester.getRect(find.byType(KartCardSurface));
    final job = tester.getRect(find.text('TECH ENTREPRENEUR'));
    final phone = tester.getRect(find.text('+221 77 000 00 00'));
    final city = tester.getRect(find.text('Dakar, Sénégal'));
    final button = tester.getRect(find.byKey(const Key('customize-public-card')));

    // Remontés : le premier contact suit le titre de près (avant, les
    // contacts étaient collés au bas de la carte).
    expect(phone.top - job.bottom, lessThan(30));
    expect(phone.top, lessThan(card.center.dy));
    expect(city.bottom, lessThan(button.top));
    // Le bouton est en bas de la carte, à sa marge près.
    expect(card.bottom - button.bottom, lessThan(30));
  });

  testWidgets('un champ vide ou masqué ne laisse pas de ligne', (tester) async {
    await _pump(
      tester,
      const KartCardData(fullName: 'Adama Dabo', email: 'adama@sankoragroup.com'),
      onCustomize: () {},
    );

    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    expect(find.byIcon(Icons.mail_outline), findsOneWidget);
  });

  testWidgets('bouton sur une ligne, 48 px de haut, seul geste de la face',
      (tester) async {
    var taps = 0;
    await _pump(tester, _full, onCustomize: () => taps++);

    final button = find.byKey(const Key('customize-public-card'));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.text('Personnaliser ma carte')).height, lessThan(24));

    await tester.tap(button);
    expect(taps, 1);

    // Ailleurs sur la face : aucun geste, comme avant.
    await tester.tap(find.text('Adama Dabo'));
    expect(taps, 1);
  });

  testWidgets('sans callback (mode minimal) : pas de bouton', (tester) async {
    await _pump(tester, _full);

    expect(find.byKey(const Key('customize-public-card')), findsNothing);
  });

  testWidgets('iPhone SE (carte de 240 × 283) : rien ne déborde, texte ≥ 11 px',
      (tester) async {
    // Tout au plus long : entreprise sur sa propre ligne, nom et titre sur
    // deux lignes, trois contacts. Un débordement ferait échouer le test.
    await _pump(
      tester,
      const KartCardData(
        fullName: 'Mouhamadou-Moustapha Abdourahmane Ndiaye',
        jobTitle: 'Responsable du développement commercial',
        brandName: 'Cabinet Médical Ahmadina Saliou (CMAS)',
        phone: '+221 77 123 45 67',
        email: 'mouhamadou.moustapha.abdourahmane@exemple-long.test',
        city: 'Saint-Louis',
        badgeLabel: 'PRO',
        tint: Color(0xFF0B2B5B),
      ),
      width: 240,
      onCustomize: () {},
    );
    await tester.pump();
    await tester.pump();

    final card = tester.getRect(find.byType(KartCardSurface));
    final button = tester.getRect(find.byKey(const Key('customize-public-card')));
    expect(card.width, 240);
    expect(card.height, closeTo(283, 0.5));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(button.bottom, lessThanOrEqualTo(card.bottom));
    final city = tester.getRect(find.byIcon(Icons.location_on_outlined));
    expect(city.bottom, lessThanOrEqualTo(button.top));

    // Lignes de contact et bouton : jamais sous 11 px à l'écran (taille de
    // la police × réduction éventuelle du bloc).
    for (final text in ['+221 77 123 45 67', 'Saint-Louis']) {
      final widget = tester.widget<Text>(find.text(text));
      expect(widget.style!.fontSize, greaterThanOrEqualTo(11));
      final rendered = tester.getSize(find.text(text)).height;
      final laidOut = tester.renderObject<RenderBox>(find.text(text)).size.height;
      expect(rendered, closeTo(laidOut, 0.01));
    }
  });
}

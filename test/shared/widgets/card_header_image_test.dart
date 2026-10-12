import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/shared/widgets/card_header_image.dart';

/// PNG 1 × 1 valide.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// « ok-… » se charge, tout le reste échoue au décodage.
ImageProvider _provider(String url) =>
    MemoryImage(url.startsWith('ok') ? _png : Uint8List.fromList([1, 2, 3]));

Future<void> _pump(WidgetTester tester, {String? avatar, String? logo}) async {
  await tester.pumpWidget(MaterialApp(
    home: Center(
      child: CardHeaderImage(
        size: 64,
        avatarUrl: avatar,
        logoUrl: logo,
        imageProvider: _provider,
        initials: const Text('AD'),
      ),
    ),
  ));
  // Laisse les images se décoder (ou échouer).
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
}

const _avatar = Key('header-image-avatar');
const _logo = Key('header-image-logo');

void main() {
  testWidgets('avec photo : la photo, jamais le logo à côté', (tester) async {
    await _pump(tester, avatar: 'ok-photo', logo: 'ok-logo');

    expect(tester.widget<Image>(find.byKey(_avatar)).fit, BoxFit.cover);
    expect(find.byKey(_logo), findsNothing);
  });

  testWidgets('sans photo : le logo, entier sur fond crème', (tester) async {
    await _pump(tester, logo: 'ok-logo');

    expect(find.byKey(_avatar), findsNothing);
    expect(tester.widget<Image>(find.byKey(_logo)).fit, BoxFit.contain);
    final cream = tester.widget<Container>(
        find.ancestor(of: find.byType(RawImage), matching: find.byType(Container)).first);
    expect(cream.color, CardHeaderImage.logoBackground);
  });

  testWidgets('photo qui ne se charge pas : le logo prend sa place', (tester) async {
    await _pump(tester, avatar: 'cassee', logo: 'ok-logo');

    expect(find.byKey(_logo), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('ni photo ni logo, ou rien ne se charge : les initiales', (tester) async {
    await _pump(tester);
    expect(find.text('AD'), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await _pump(tester, avatar: 'cassee', logo: 'casse');
    expect(find.text('AD'), findsOneWidget);
    // Aucune image réellement peinte : ni image cassée, ni cadre vide.
    expect(find.byType(RawImage), findsNothing);
  });
}

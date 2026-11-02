// Highlight d'un événement : la personne inscrite peut le retirer de sa
// carte puis l'y remettre depuis la fiche de l'événement. Données fictives.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/contacts/models/highlight_model.dart';
import 'package:kart_app/features/contacts/providers/highlight_provider.dart';
import 'package:kart_app/features/contacts/ui/event_highlight_detail_page.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:provider/provider.dart';

class _FakeApi implements HttpClientAdapter {
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final key = '${options.method} ${options.uri.path.replaceFirst(RegExp(r'^.*/api'), '')}';
    calls.add(key);
    final Object body = switch (key) {
      'GET /events/7/attendees' => {
          'event': {'id': 7, 'name': 'Salon Exemple', 'starts_at': '2026-12-11T09:00:00Z', 'ends_at': '2026-12-13T18:00:00Z'},
          'attendees': [],
        },
      'GET /highlights' => [],
      _ => {'message': 'ok'},
    };
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

class _Auth extends AuthProvider {
  _Auth() {
    user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: 'awa@example.com', plan: 'pro');
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('retirer puis remettre le highlight de l\'événement sur sa carte', (tester) async {
    final api = _FakeApi();
    ApiClient.dio.httpClientAdapter = api;
    final highlight = HighlightModel.fromJson({'id': 42, 'name': 'Salon Exemple', 'is_active': false, 'is_company_event': true, 'event_id': 7});

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _Auth()),
        ChangeNotifierProvider(create: (_) => HighlightProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: EventHighlightDetailPage(eventId: 7, fallbackName: 'Salon Exemple', highlight: highlight),
      ),
    ));
    await _settle(tester);

    final toggle = find.byKey(const Key('event-highlight-on-card'));
    expect(toggle, findsOneWidget);
    expect(find.text('Retiré de votre carte. Vous pouvez le remettre à tout moment.'), findsOneWidget);

    await tester.tap(toggle);
    await _settle(tester);
    expect(api.calls, contains('POST /highlights/42/activate'));
    expect(find.text('Votre carte montre cet événement. Vous pouvez le retirer à tout moment.'), findsOneWidget);

    await tester.tap(toggle);
    await _settle(tester);
    expect(api.calls, contains('POST /highlights/42/deactivate'));
    expect(find.text('Retiré de votre carte. Vous pouvez le remettre à tout moment.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}

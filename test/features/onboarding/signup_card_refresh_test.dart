// Parcours d'inscription : après l'étape « poste » de l'onboarding, la carte
// de l'app (CardProvider) reprend le poste saisi au lieu de rester sur
// l'état chargé avant l'onboarding (sans poste, ou « Créez votre carte »).
// Données fictives.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/features/onboarding/data/profile_setup_api.dart';
import 'package:kart_app/features/onboarding/ui/profile_setup/profile_setup_page.dart';
import 'package:kart_app/features/profile_completion/providers/profile_completion_provider.dart';
import 'package:kart_app/features/profile_completion/services/profile_completion_service.dart';
import 'package:provider/provider.dart';

/// Faux serveur partagé : l'onboarding y enregistre, la carte de l'app y lit.
class _Server extends ProfileSetupApi implements HttpClientAdapter {
  Map<String, dynamic> card = {'has_card': false};

  @override
  Future<Map<String, dynamic>> fetchCard() async => card;

  @override
  Future<void> saveCard(Map<String, dynamic> fields) async {
    card = {...card, 'has_card': true, ...fields};
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      ResponseBody.fromString(jsonEncode(options.uri.path.endsWith('/me/card-summary') ? card : {}), 200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  void close({bool force = false}) {}
}

class _Auth extends AuthProvider {
  _Auth() {
    user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: 'awa@example.com', plan: 'pro', onboardingRequired: true);
  }

  @override
  Future<bool> completeOnboarding() async => true;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
  });

  testWidgets('la carte de l\'app reprend le poste saisi pendant l\'onboarding', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final server = _Server();
    ApiClient.dio.httpClientAdapter = server;
    final card = CardProvider();
    // État préchargé par le splash avant l'onboarding : pas encore de carte.
    await tester.runAsync(card.loadCardSummary);
    expect(card.status, CardStatus.noCard);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _Auth()),
        ChangeNotifierProvider<CardProvider>.value(value: card),
        ChangeNotifierProvider(create: (_) => ProfileCompletionProvider(ProfileCompletionService())),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: ProfileSetupPage(api: server)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-later'))); // photo
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Juriste');
    await tester.enterText(find.byType(TextField).at(1), 'Cabinet Exemple');
    await tester.tap(find.byKey(const Key('onboarding-primary')));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(card.status, CardStatus.hasCard);
    expect(card.jobTitle, 'Juriste');
    expect(card.company, 'Cabinet Exemple');
  });
}

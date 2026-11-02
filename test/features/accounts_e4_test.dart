// Lot E4 : pastille gardée après fermeture de l'app, bannière « carte
// invisible » (une fois par semaine, trois fois en tout), second numéro
// WhatsApp, logo et couleurs de l'entreprise. Données fictives.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/network/api_client.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/company_info/services/company_branding_service.dart';
import 'package:kart_app/features/company_info/widgets/company_branding_section.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/features/explore/providers/connection_badge_provider.dart';
import 'package:kart_app/features/explore/widgets/hidden_card_banner.dart';
import 'package:kart_app/features/profile_completion/model/profile_completion_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi implements HttpClientAdapter {
  final Map<String, Object?> bodies = {};
  final Map<String, Object> routes;

  _FakeApi(this.routes);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final key = '${options.method} ${options.uri.path.replaceFirst(RegExp(r'^.*/api'), '')}';
    bodies[key] = options.data;
    final body = routes[key] ?? {'message': 'absent'};
    return ResponseBody.fromString(jsonEncode(body), routes.containsKey(key) ? 200 : 404,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

class _FakeBranding extends CompanyBrandingService {
  final List<Map<String, String?>> saved = [];

  @override
  Future<Map<String, dynamic>> uploadLogo(String localPath) async => {
        'logo': 'company_logos/logo.png',
        'brand_colors': ['#0F5C4A', '#E8B04B', '#1A1A1A'],
      };

  @override
  Future<Map<String, dynamic>> saveColors({required String primary, String? secondary}) async {
    saved.add({'primary': primary, 'secondary': secondary});
    return {'primary_color': primary};
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('Pastille des demandes', () {
    test('le dernier chiffre est gardé et relu à l\'ouverture suivante', () async {
      SharedPreferences.setMockInitialValues({ConnectionBadgeProvider.prefsKey: 4});
      final provider = ConnectionBadgeProvider();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(provider.pendingReceivedCount, 4);

      provider.clearBadge();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((await SharedPreferences.getInstance()).getInt(ConnectionBadgeProvider.prefsKey), 0);
    });
  });

  group('Bannière carte invisible', () {
    test('au plus une fois par semaine, trois fois en tout', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final start = DateTime(2026, 11, 2, 10);

      expect(await HiddenCardBanner.claimDisplay(prefs, start), isTrue);
      expect(await HiddenCardBanner.claimDisplay(prefs, start.add(const Duration(days: 3))), isFalse);
      expect(await HiddenCardBanner.claimDisplay(prefs, start.add(const Duration(days: 7))), isTrue);
      expect(await HiddenCardBanner.claimDisplay(prefs, start.add(const Duration(days: 14))), isTrue);
      expect(await HiddenCardBanner.claimDisplay(prefs, start.add(const Duration(days: 60))), isFalse);
    });

    testWidgets('« Rendre ma carte visible » rend la carte publique et listée', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = _FakeApi({
        'GET /me/card-summary': {'has_card': true, 'job_title': 'Juriste', 'company': '', 'is_public': true, 'listed_in_directory': false},
        'PUT /me/card-summary': {'success': true},
      });
      ApiClient.dio.httpClientAdapter = api;
      final card = CardProvider();
      await tester.runAsync(card.loadCardSummary);
      expect(card.isHiddenFromExplore, isTrue);

      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: card,
        child: MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: HiddenCardBanner())),
      ));
      await _settle(tester);
      expect(find.text('Votre carte est invisible dans Explorer'), findsOneWidget);

      await tester.tap(find.text('Rendre ma carte visible'));
      await _settle(tester);
      expect(api.bodies['PUT /me/card-summary'], {'is_public': true, 'listed_in_directory': true});
      expect(card.isHiddenFromExplore, isFalse);
      expect(find.text('Votre carte est invisible dans Explorer'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
    });
  });

  test('second numéro : lu et envoyé avec la carte', () {
    final model = ProfileCompletionModel.fromJson({'phone': '+221770000001', 'whatsapp_phone': '+221780000002'});
    expect(model.whatsappPhone, '+221780000002');
    expect(model.toJson()['whatsapp_phone'], '+221780000002');
  });

  testWidgets('logo de l\'entreprise : couleurs extraites proposées, puis enregistrées', (tester) async {
    final service = _FakeBranding();
    var reloaded = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompanyBrandingSection(
            company: const {'name': 'Société Exemple'},
            onChanged: () => reloaded++,
            service: service,
            pickImage: () async => '/tmp/logo-fictif.png',
          ),
        ),
      ),
    ));
    expect(find.text('Couleur principale'), findsNothing);

    await tester.tap(find.text('Changer le logo'));
    await _settle(tester);
    expect(find.text('Couleur principale'), findsOneWidget);
    expect(find.bySemanticsLabel('Couleur principale #0F5C4A'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Couleur principale #0F5C4A'));
    await tester.tap(find.bySemanticsLabel('Couleur secondaire #E8B04B'));
    await tester.pump();
    await tester.tap(find.text('Enregistrer les couleurs'));
    await _settle(tester);

    expect(service.saved.single, {'primary': '#0F5C4A', 'secondary': '#E8B04B'});
    expect(reloaded, 2);
    await tester.pump(const Duration(seconds: 6));
  });
}

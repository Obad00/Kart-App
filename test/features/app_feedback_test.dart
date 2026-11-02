// Retours du 2 novembre : couleurs de l'entreprise appliquées tout de suite,
// fenêtres de saisie en verre dépoli, filtres instantanés (local, cache,
// annulation), message « Email vérifié » centré, lien universel de
// vérification d'email. Données fictives.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/deep_links/deep_link_service.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/core/ui/feedback/feedback_overlay.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/company_community/models/event_invitation.dart';
import 'package:kart_app/features/company_community/services/event_invitations_service.dart';
import 'package:kart_app/features/company_community/ui/event_invitations_tab.dart';
import 'package:kart_app/features/company_info/utils/branding_refresh.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/features/onboarding/providers/company_provider.dart';
import 'package:kart_app/shared/widgets/filter_pill_chip.dart';
import 'package:kart_app/shared/widgets/glass_dialog.dart';
import 'package:provider/provider.dart';

class _Auth extends AuthProvider {
  int loads = 0;
  _Auth() {
    user = User(id: 1, firstname: 'Awa', lastname: 'Exemple', email: 'awa@example.com', plan: 'pro');
  }
  @override
  bool get isInitialized => true;
  @override
  Future<void> loadMe() async => loads++;
}

class _Card extends CardProvider {
  int loads = 0;
  @override
  Future<void> loadCardSummary() async => loads++;
}

class _Company extends CompanyProvider {
  int loads = 0;
  @override
  Future<void> loadMyCompany() async => loads++;
}

EventInvitation _invitation(int id, String name, InvitationStatus status) => EventInvitation(
      id: id,
      name: name,
      firstName: name.split(' ').first,
      lastName: 'Exemple',
      phone: '+22177000000$id',
      status: status,
      sentAt: status == InvitationStatus.pending ? null : DateTime(2026, 11, 1),
    );

/// Serveur lent et contrôlé : chaque appel attend qu'on le libère.
class _SlowService extends EventInvitationsService {
  final calls = <({InvitationStatus? status, CancelToken? token, Completer<InvitationPage> done})>[];
  final all = [
    _invitation(1, 'Awa Exemple', InvitationStatus.confirmed),
    _invitation(2, 'Moussa Exemple', InvitationStatus.pending),
    _invitation(3, 'Fatou Exemple', InvitationStatus.declined),
  ];

  InvitationPage page(InvitationStatus? status) => InvitationPage(
        items: all.where((i) => i.matches(status: status)).toList(),
        counts: const InvitationCounts(),
        categories: const [],
        currentPage: 1,
        lastPage: 1,
      );

  @override
  Future<InvitationPage> list(int eventId,
      {InvitationStatus? status, String? category, String? query, int page = 1, CancelToken? cancelToken}) {
    final done = Completer<InvitationPage>();
    calls.add((status: status, token: cancelToken, done: done));
    return done.future;
  }

  @override
  Future<({EventInvitation? next, int remaining})> next(int eventId) async => (next: null, remaining: 0);
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
}

void main() {
  testWidgets('couleurs ou logo changés : carte, entreprise et compte relus tout de suite', (tester) async {
    final auth = _Auth();
    final card = _Card();
    final company = _Company();
    late BuildContext context;
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<CardProvider>.value(value: card),
        ChangeNotifierProvider<CompanyProvider>.value(value: company),
      ],
      child: MaterialApp(home: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      })),
    ));

    await refreshAfterBrandingChange(context);

    expect([company.loads, card.loads, auth.loads], [1, 1, 1]);
  });

  testWidgets('fenêtre de saisie : même verre que les autres, valeur renvoyée', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await GlassDialog.input(context,
              title: 'Nouvelle catégorie', label: 'Nom de la catégorie', icon: Icons.sell_outlined),
          child: const Text('Ouvrir'),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.enterText(find.descendant(of: find.byKey(const Key('glass-input-field')), matching: find.byType(TextField)), '  Presse ');
    await tester.tap(find.byKey(const Key('glass-input-confirm')));
    await tester.pumpAndSettle();
    expect(result, 'Presse');
  });

  testWidgets('filtre instantané : liste locale tout de suite, cache, requête dépassée annulée', (tester) async {
    final service = _SlowService();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: ChangeNotifierProvider<CardProvider>(
        create: (_) => _Card(),
        child: Scaffold(body: EventInvitationsTab(eventId: 1, topPadding: 0, service: service, visible: false)),
      ),
    ));
    await _frames(tester);
    service.calls.single.done.complete(service.page(null));
    await _frames(tester);
    expect(find.text('Moussa Exemple'), findsOneWidget);

    // « Confirmée » : affiché avant toute réponse du serveur.
    final stopwatch = Stopwatch()..start();
    await tester.tap(find.widgetWithText(FilterPillChip, 'Confirmée'));
    await tester.pump();
    stopwatch.stop();
    expect(find.text('Awa Exemple'), findsOneWidget);
    expect(find.text('Moussa Exemple'), findsNothing);
    expect(service.calls.last.status, InvitationStatus.confirmed);
    expect(service.calls.last.done.isCompleted, isFalse);
    // ignore: avoid_print
    print('Filtre « Confirmée » affiché en ${stopwatch.elapsedMilliseconds} ms (sans attendre le serveur)');

    // Changement avant la réponse : la requête précédente est annulée.
    await tester.tap(find.widgetWithText(FilterPillChip, 'Déclinée'));
    await tester.pump();
    expect(service.calls[service.calls.length - 2].token!.isCancelled, isTrue);
    expect(find.text('Fatou Exemple'), findsOneWidget);
    service.calls.last.done.complete(service.page(InvitationStatus.declined));
    await _frames(tester);

    // Retour à « Toutes » : page en cache, immédiate.
    await tester.tap(find.widgetWithText(FilterPillChip, 'Toutes'));
    await tester.pump();
    expect(find.text('Moussa Exemple'), findsOneWidget);
    expect(find.text('Awa Exemple'), findsOneWidget);
    for (final call in service.calls.where((c) => !c.done.isCompleted)) {
      call.done.complete(service.page(call.status));
    }
    await _frames(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('« Email vérifié » : au centre de l\'écran, environ 2,5 s', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
          onPressed: () => FeedbackOverlay.showSuccess(context,
              title: 'Email vérifié',
              subtitle: 'Votre adresse est confirmée.',
              duration: const Duration(milliseconds: 2500),
              centered: true),
          child: const Text('Valider'),
        ),
        ),
      ),
    ));
    await tester.tap(find.text('Valider'));
    await tester.pump(const Duration(milliseconds: 500));

    final center = tester.getCenter(find.text('Email vérifié'));
    final screen = tester.getSize(find.byType(MaterialApp));
    expect((center.dy - screen.height / 2).abs(), lessThan(80));
    // Encore là à 2,4 s, parti après 2,5 s et le fondu de sortie.
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('Email vérifié'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Email vérifié'), findsNothing);
  });

  test('lien universel de vérification : appel API avec les mêmes paramètres signés', () {
    const hash = 'f2c71be2094d766fa7dc7550905e9c62c1929473';
    final link = Uri.parse('https://kart.business/verifier-email/42/$hash?expires=1793659898&nonce=abc&signature=def');

    expect(DeepLinkService.emailVerificationApiPath(link),
        '/auth/verify-email/42/$hash?expires=1793659898&nonce=abc&signature=def');
    expect(DeepLinkService.emailVerificationApiPath(Uri.parse('https://autre.example/verifier-email/42/$hash?x=1')), isNull);
    expect(DeepLinkService.emailVerificationApiPath(Uri.parse('http://kart.business/verifier-email/42/$hash')), isNull);
    expect(DeepLinkService.emailVerificationApiPath(Uri.parse('https://kart.business/card/awa')), isNull);
    expect(DeepLinkService.emailVerificationApiPath(Uri.parse('kart://explore/requests')), isNull);
  });
}

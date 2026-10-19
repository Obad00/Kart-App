import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/auth/models/profile_score.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/auth/providers/auth_provider.dart';
import 'package:kart_app/features/onboarding/data/profile_setup_api.dart';
import 'package:kart_app/features/onboarding/ui/profile_setup/profile_setup_page.dart';
import 'package:kart_app/features/profile/ui/notification_settings_page.dart';
import 'package:kart_app/features/profile_completion/providers/candidate_skills_provider.dart';
import 'package:kart_app/features/profile_completion/providers/profile_completion_provider.dart';
import 'package:kart_app/features/profile_completion/services/candidate_skills_service.dart';
import 'package:kart_app/features/profile_completion/services/profile_completion_service.dart';
import 'package:kart_app/features/profile_completion/widgets/completion_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Score renvoyé par /me : photo et poste faits, il manque le contact (20).
const _me = {
  'id': 1, 'firstname': 'Awa', 'lastname': 'Diop', 'email': 'awa.diop@example.test', 'plan': 'pro',
  'preferences': {'profile_reminders': true},
  'profile_score': {
    'score': 30,
    'next': {'key': 'contact', 'label': 'Moyen de contact affiché', 'weight': 20},
    'criteria': [
      {'key': 'photo', 'label': 'Photo de profil', 'weight': 15, 'done': true},
      {'key': 'job_title', 'label': 'Poste', 'weight': 15, 'done': true},
      {'key': 'contact', 'label': 'Moyen de contact affiché', 'weight': 20, 'done': false},
      {'key': 'company', 'label': 'Entreprise', 'weight': 10, 'done': false},
      {'key': 'bio', 'label': 'Bio', 'weight': 10, 'done': false},
    ],
  },
};

class _Auth extends AuthProvider {
  _Auth(Map<String, dynamic> json) {
    user = User.fromJson(json);
  }
  final List<bool> reminders = [];

  @override
  Future<bool> setProfileReminders(bool enabled) async {
    reminders.add(enabled);
    user = User.fromJson({..._me, 'preferences': {'profile_reminders': enabled}});
    notifyListeners();
    return true;
  }

  @override
  Future<bool> completeOnboarding() async => fail("une étape seule ne doit pas terminer l'onboarding");
}

class _NoNetworkCompletion extends ProfileCompletionProvider {
  _NoNetworkCompletion() : super(ProfileCompletionService());
  @override
  Future<void> load() async {}
}

class _NoNetworkSkills extends CandidateSkillsProvider {
  _NoNetworkSkills() : super(CandidateSkillsService());
  @override
  Future<void> load() async {}
}

class _Api extends ProfileSetupApi {
  @override
  Future<Map<String, dynamic>> fetchCard() async => {'phone': '+221770000001', 'activated_fields': []};
  @override
  Future<void> saveCard(Map<String, dynamic> fields) async {}
}

Widget _wrap(AuthProvider auth, Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<ProfileCompletionProvider>(create: (_) => _NoNetworkCompletion()),
        ChangeNotifierProvider<CandidateSkillsProvider>(create: (_) => _NoNetworkSkills()),
      ],
      child: MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
    for (final f in {'Syne': 'assets/fonts/Syne.ttf', 'Archivo': 'assets/fonts/Archivo.ttf'}.entries) {
      await (FontLoader(f.key)..addFont(Future.value(ByteData.view(File(f.value).readAsBytesSync().buffer)))).load();
    }
  });

  test('le score de /me est lu, avec l\'élément suivant', () {
    final score = User.fromJson(Map<String, dynamic>.from(_me)).profileScore!;
    expect(score.score, 30);
    expect(score.next!.key, 'contact');
    expect(score.criteria.where((c) => !c.done).length, 3);
    // Serveur plus ancien : pas de score, l'app garde son calcul local.
    expect(User.fromJson({'id': 1, 'firstname': 'A', 'lastname': 'D', 'email': 'a@b.c', 'plan': 'pro'}).profileScore, isNull);
    expect(ProfileScore.fromJson('rien'), isNull);
  });

  testWidgets('la carte affiche le score du serveur et l\'élément suivant, et l\'ouvre au toucher', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(_wrap(
      _Auth(Map<String, dynamic>.from(_me)),
      CompletionBanner(onOpen: (_, key) async => opened.add(key)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('30% complété'), findsOneWidget);
    expect(find.text('Ensuite : Moyen de contact affiché'), findsOneWidget);
    expect(find.text('+20 %'), findsOneWidget);
    // Les autres manques, sans répéter l'élément suivant.
    expect(find.text('Entreprise'), findsOneWidget);

    await tester.tap(find.byKey(const Key('completion-banner')));
    await tester.pumpAndSettle();
    expect(opened, ['contact']);
  });

  testWidgets('une étape seule se referme sans terminer l\'onboarding', (tester) async {
    bool? closedWith;
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: _Auth(Map<String, dynamic>.from(_me)),
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              closedWith = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ProfileSetupPage(api: _Api(), singleStep: 2)));
            },
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Comment vous joindre'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-skip-all')), findsNothing);
    await tester.tap(find.byKey(const Key('onboarding-primary')));
    await tester.pumpAndSettle();

    expect(closedWith, isTrue);
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('interrupteur des rappels : enregistré, et grisé sans notifications push', (tester) async {
    SharedPreferences.setMockInitialValues({'push_notifications_enabled': true});
    final auth = _Auth(Map<String, dynamic>.from(_me));
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(theme: AppTheme.dark(), home: const NotificationSettingsPage()),
    ));
    await tester.pumpAndSettle();

    Switch reminder() => tester.widget<Switch>(find.descendant(of: find.byKey(const Key('profile-reminders')), matching: find.byType(Switch)));
    expect(find.text('Rappels pour compléter mon profil'), findsOneWidget);
    expect(reminder().value, isTrue);

    await tester.tap(find.descendant(of: find.byKey(const Key('profile-reminders')), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(auth.reminders, [false]);
    expect(reminder().value, isFalse);

    // Notifications push coupées sur l'appareil : rappels impossibles.
    SharedPreferences.setMockInitialValues({'push_notifications_enabled': false});
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(theme: AppTheme.dark(), home: const NotificationSettingsPage()),
    ));
    await tester.pumpAndSettle();
    expect(reminder().onChanged, isNull);
    expect(find.text("Activez d'abord les notifications push."), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'config/feature_flags.dart';
import 'core/deep_links/deep_link_service.dart';
import 'core/services/connectivity_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/widgets/offline_banner.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/digital_card/providers/card_provider.dart';
import 'features/navigation/home_shell.dart';

import 'features/contacts/providers/highlight_provider.dart';
import 'features/contacts/providers/contacts_provider.dart';
import 'features/onboarding/providers/company_provider.dart';
import 'features/plans/providers/plan_provider.dart';
import 'features/plans/services/plan_service.dart';

// Payment
import 'features/payment/providers/payment_provider.dart';
import 'features/payment/models/payment.dart';

// Card Scanner
import 'features/card_scanner/providers/card_scan_provider.dart';

// Leads
import 'features/leads/providers/leads_provider.dart';
import 'features/leads/ui/leads_page.dart';

import 'features/digital_card/ui/my_digital_card_guard.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/login_page.dart';
import 'features/auth/ui/forgot_password_page.dart';
import 'features/auth/ui/register_page.dart';
import 'features/auth/ui/complete_profile_page.dart';
import 'features/auth/ui/force_change_password_page.dart';
import 'features/auth/ui/change_password_page.dart';
import 'features/onboarding/ui/onboarding_company_choice_page.dart';
import 'features/onboarding/ui/create_company_page.dart';
import 'features/onboarding/ui/join_company_page.dart';
import 'features/company_info/ui/company_info_page.dart';
import 'features/plans/ui/plan_selection_page.dart';
import 'package:kart_app/features/scan/ui/scan_page.dart';

// Payment screens
import 'features/payment/ui/plans_screen.dart';
import 'features/payment/ui/payment_method_screen.dart';
import 'features/payment/ui/payment_processing_screen.dart';
import 'features/payment/ui/payment_result_screen.dart';

// Card Scanner screens
import 'features/card_scanner/ui/card_scanner_screen.dart';
import 'features/card_scanner/ui/image_preview_screen.dart';
import 'features/card_scanner/ui/scan_result_screen.dart';

import 'features/profile_completion/providers/profile_completion_provider.dart';
import 'features/profile_completion/services/profile_completion_service.dart';
import 'features/profile_completion/providers/candidate_skills_provider.dart';
import 'features/profile_completion/services/candidate_skills_service.dart';
import 'features/jobmatch/providers/jobmatch_provider.dart';
import 'features/jobmatch/services/jobmatch_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const KartApp());
}

class KartApp extends StatefulWidget {
  const KartApp({super.key});

  @override
  State<KartApp> createState() => _KartAppState();
}

class _KartAppState extends State<KartApp> {
  late final DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService(navigatorKey)..init();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => HighlightProvider()),
        ChangeNotifierProvider(
            create: (_) => ContactsProvider()..fetchGroupedContacts()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(
            create: (_) => PlanProvider(service: PlanService())),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => CardScanProvider()),
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileCompletionProvider(
            ProfileCompletionService(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CandidateSkillsProvider(
            CandidateSkillsService(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => JobMatchProvider(JobMatchService()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => ShowCaseWidget(
                builder: (context) => Column(
                  children: [
                    const OfflineBanner(),
                    Expanded(child: child!),
                  ],
                ),
                // Boutons Précédent/Passer/Suivant affichés sur CHAQUE guide
                // de l'app (tous écrans confondus) — pas besoin de les
                // redéfinir par tour. "Passer" ferme juste l'overlay ; le
                // guide est déjà marqué comme vu dès son démarrage (cf.
                // TourPrefs), donc il ne revient pas au prochain lancement.
                globalTooltipActionConfig: const TooltipActionConfig(
                  position: TooltipActionPosition.outside,
                  alignment: MainAxisAlignment.spaceBetween,
                ),
                globalTooltipActions: [
                  TooltipActionButton(
                    type: TooltipDefaultActionType.previous,
                    name: 'Précédent',
                    backgroundColor: Colors.transparent,
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TooltipActionButton(
                    type: TooltipDefaultActionType.skip,
                    name: 'Passer',
                    backgroundColor: Colors.transparent,
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TooltipActionButton(
                    type: TooltipDefaultActionType.next,
                    name: 'Suivant',
                    backgroundColor: Colors.white,
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeProvider.themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr', 'FR'),
                Locale('en', 'US'),
              ],
              locale: const Locale('fr', 'FR'),

              /// 🔐 ROUTE PAR DÉFAUT (OBLIGATOIRE)
              initialRoute: '/',

              routes: {
                '/': (_) => const SplashScreen(),
                '/splash': (_) => const SplashScreen(),
                '/login': (_) => const LoginPage(),
                '/register': (_) => const RegisterPage(),
                '/forgot-password': (_) => const ForgotPasswordPage(),
                '/complete-profile': (_) => const CompleteProfilePage(),
                '/force-change-password': (_) =>
                    const ForceChangePasswordPage(),
                '/change-password': (_) => const ChangePasswordPage(),
                '/my-company': (_) => const CompanyInfoPage(),

                // Plans
                '/plans': (_) => const PlanSelectionPage(),

                // Payment
                '/payment/plans': (_) => const PlansScreen(),
                '/payment/methods': (_) => const PaymentMethodScreen(),
                '/payment/processing': (_) => const PaymentProcessingScreen(),
                '/payment/result': (context) {
                  final payment =
                      ModalRoute.of(context)?.settings.arguments as Payment;
                  return PaymentResultScreen(payment: payment);
                },

                // Card Scanner
                '/card-scanner': (_) => const CardScannerScreen(),
                '/card-scanner/preview': (_) => const ImagePreviewScreen(),
                '/card-scanner/result': (_) => const ScanResultScreen(),

                // Onboarding (fonctionnalités Entreprise — masquées via FeatureFlags)
                if (FeatureFlags.businessFeaturesEnabled) ...{
                  '/onboarding-company': (_) =>
                      const OnboardingCompanyChoicePage(),
                  '/create-company': (_) => const CreateCompanyPage(),
                  '/company/create': (_) => const CreateCompanyPage(),
                  '/join-company': (_) => const JoinCompanyPage(),
                },

                '/scan': (_) => const ScanPage(),
                '/my-card': (_) => const MyDigitalCardGuard(),
                '/leads': (_) => const LeadsPage(),
                '/home': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments
                      as Map<String, dynamic>?;

                  return HomeShell(
                    initialIndex: args?['tab'] ?? 0,
                    forceTourReplay: args?['replayTour'] ?? false,
                    openLikedJobs: args?['openLikedJobs'] ?? false,
                  );
                },
              },
              onUnknownRoute: (settings) => MaterialPageRoute(
                builder: (_) => const HomeShell(),
              ),
            ),
          );
        },
      ),
    );
  }
}

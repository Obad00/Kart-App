import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/feature_flags.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

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
import 'features/auth/ui/register_page.dart';
import 'features/auth/ui/complete_profile_page.dart';
import 'features/onboarding/ui/onboarding_company_choice_page.dart';
import 'features/onboarding/ui/create_company_page.dart';
import 'features/onboarding/ui/join_company_page.dart';
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

void main() {
  runApp(const KartApp());
}

class KartApp extends StatelessWidget {
  const KartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
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
                '/complete-profile': (_) => const CompleteProfilePage(),

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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';


import 'features/auth/providers/auth_provider.dart';
import 'features/digital_card/providers/card_provider.dart';
import 'features/navigation/home_shell.dart';

import 'features/contacts/providers/highlight_provider.dart';
import 'features/contacts/providers/contacts_provider.dart';
import 'features/onboarding/providers/company_provider.dart';

import 'features/digital_card/ui/my_digital_card_guard.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/login_page.dart';
import 'features/auth/ui/register_page.dart';
import 'features/onboarding/ui/onboarding_choice_page.dart';
import 'features/onboarding/ui/onboarding_company_choice_page.dart';
import 'features/onboarding/ui/create_company_page.dart';
import 'features/onboarding/ui/join_company_page.dart';




void main() {
  runApp(const KartApp());
}

class KartApp extends StatelessWidget {
  const KartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => HighlightProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()..fetchGroupedContacts(),),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,

        /// 🔐 ROUTE PAR DÉFAUT (OBLIGATOIRE)
        initialRoute: '/',

        routes: {
          '/': (_) => const SplashScreen(), 
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),

          
          // Onboarding
          '/onboarding-choice': (_) => const OnboardingChoicePage(),
          '/onboarding-company': (_) => const OnboardingCompanyChoicePage(),
          '/create-company': (_) => const CreateCompanyPage(),
          '/join-company': (_) => const JoinCompanyPage(),


          '/my-card': (_) => const MyDigitalCardGuard(),
          '/home': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

            return HomeShell(
              initialIndex: args?['tab'] ?? 0,
            );
          },
        },
      ),
    );
  }
}

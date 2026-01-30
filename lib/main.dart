import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/ui/splash_screen.dart';
import 'features/auth/ui/login_page.dart';
import 'features/auth/ui/register_page.dart';
import 'features/digital_card/providers/card_provider.dart';
import 'features/digital_card/ui/my_digital_card_guard.dart';
import 'features/navigation/home_shell.dart';
import 'core/theme/app_theme.dart';

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/my-card': (_) => const MyDigitalCardGuard(),
          '/home': (_) => const HomeShell(),
        },
      ),
    );
  }
}

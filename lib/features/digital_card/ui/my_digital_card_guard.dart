import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'my_digital_card_page.dart';

/// Auth Guard pour protéger l'accès à MyDigitalCardPage.
///
/// Redirects vers /login si l'utilisateur n'est pas authentifié.
/// Charge automatiquement le QR card au premier accès.
class MyDigitalCardGuard extends StatelessWidget {
  const MyDigitalCardGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Rediriger si non authentifié
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: SizedBox.expand(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Utilisateur authentifié → afficher la carte
        return MyDigitalCardPage();
      },
    );
  }
}

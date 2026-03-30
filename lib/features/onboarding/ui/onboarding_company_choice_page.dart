import 'package:flutter/material.dart';
import '../widgets/company_choice_card.dart';

class OnboardingCompanyChoicePage extends StatelessWidget {
  const OnboardingCompanyChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final subscriptionId = args?['subscriptionId'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Entreprise',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Title
            const Text(
              'Configurez votre entreprise',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Creez votre entreprise et gerez votre equipe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            // CREATE COMPANY
            CompanyChoiceCard(
              icon: Icons.business_rounded,
              title: 'Creer une entreprise',
              subtitle: 'Vous serez administrateur de votre equipe',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/create-company',
                  arguments: {
                    'subscriptionId': subscriptionId,
                  },
                );
              },
            ),

            const Spacer(),

            // Skip
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text(
                'Faire plus tard',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

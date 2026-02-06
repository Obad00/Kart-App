import 'package:flutter/material.dart';

class OnboardingChoicePage extends StatelessWidget {
  const OnboardingChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final successMessage = args?['successMessage'];

    if (successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const Text(
                'Comment souhaitez-vous utiliser KART ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 40),

              _ChoiceButton(
                title: 'Individuel',
                subtitle: 'Carte personnelle, usage solo',
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),

              const SizedBox(height: 16),

              _ChoiceButton(
                title: 'Entreprise',
                subtitle: 'Pour une équipe ou société',
                onTap: () {
                  Navigator.pushNamed(context, '/onboarding-company');
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

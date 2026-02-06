import 'package:flutter/material.dart';

class OnboardingCompanyChoicePage extends StatelessWidget {
  const OnboardingCompanyChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Entreprise'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _CompanyChoiceTile(
              title: 'Créer une entreprise',
              subtitle: 'Vous êtes admin de votre équipe',
              onTap: () {
                Navigator.pushNamed(context, '/create-company');
              },
            ),
            const SizedBox(height: 16),
            _CompanyChoiceTile(
              title: 'Rejoindre une entreprise',
              subtitle: 'Vous avez un code licence',
              onTap: () {
                Navigator.pushNamed(context, '/join-company');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyChoiceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CompanyChoiceTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)
      ),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
    );
  }
}

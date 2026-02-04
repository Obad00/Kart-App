import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_provider.dart';
import '../../digital_card/providers/card_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final card = context.watch<CardProvider>();

    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final fullName =
        '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👤 HEADER
          _profileHeader(colors, fullName, user['email']),

          const SizedBox(height: 28),

          // 👤 INFOS PERSONNELLES (AUTH)
          _section(
            title: 'Informations personnelles',
            children: [
              _infoTile(Icons.person, 'Prénom', user['firstname']),
              _infoTile(Icons.badge, 'Nom', user['lastname']),
              _infoTile(Icons.email, 'Email', user['email']),
            ],
          ),

          const SizedBox(height: 20),

          // 💼 INFOS PROFESSIONNELLES (DIGITAL CARD)
          _section(
            title: 'Carte digitale',
            children: card.status == CardStatus.hasCard
                ? [
                    _infoTile(Icons.work, 'Poste', card.jobTitle),
                    _infoTile(Icons.apartment, 'Entreprise', card.company),
                    _infoTile(Icons.phone, 'Téléphone', card.phone),
                    _linkedinTile(card.linkedin),
                  ]
                : [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Aucune carte digitale'),
                      subtitle:
                          Text('Créez votre carte pour afficher ces infos'),
                    ),
                  ],
          ),

          const SizedBox(height: 32),

         ElevatedButton.icon(
  icon: const Icon(Icons.logout),
  label: const Text('Se déconnecter'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.redAccent,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  },
),

        ],
      ),
    );
  }

  // ================= UI PARTS =================

  Widget _profileHeader(
      ColorScheme colors, String fullName, String? email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colors.primary,
            child: Text(
              _initials(fullName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? 'Utilisateur' : fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email ?? '',
                  style: TextStyle(
                    color: colors.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label),
      subtitle: Text(value?.isNotEmpty == true ? value! : '-'),
    );
  }

  Widget _linkedinTile(String? url) {
    if (url == null || url.isEmpty) {
      return _infoTile(Icons.link, 'LinkedIn', '-');
    }

    return ListTile(
      leading: const Icon(Icons.link),
      title: const Text('LinkedIn'),
      subtitle: Text(url),
      trailing: const Icon(Icons.open_in_new),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

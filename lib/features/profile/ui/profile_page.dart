import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_provider.dart';
import '../../digital_card/providers/card_provider.dart';


import '../../digital_card/exceptions/theme_forbidden_exception.dart';


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
        '${user.firstname} ${user.lastname}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 👤 HEADER
         _profileHeader(colors, fullName, user.email),


          const SizedBox(height: 28),

          // 👤 INFOS PERSONNELLES
          _section(
            title: 'Informations personnelles',
            children: [
              _infoTile(Icons.person, 'Prénom', user.firstname),
              _infoTile(Icons.badge, 'Nom', user.lastname),
              _infoTile(Icons.email, 'Email', user.email),

            ],
          ),

          const SizedBox(height: 20),

          // 💼 CARTE DIGITALE
          _section(
            title: 'Carte digitale',
            children: card.status == CardStatus.hasCard
                ? [
                    _infoTile(Icons.work, 'Poste', card.jobTitle),
                    _infoTile(Icons.apartment, 'Entreprise', card.company),
                    _infoTile(Icons.phone, 'Téléphone', card.phone),
                    _linkedinTile(card.linkedin),

                    const Divider(height: 1),

                    // 🎨 THEME
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Thème de la carte'),
                      subtitle: Text(_themeLabel(card.theme)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openThemePicker(context),
                    ),
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

          // 🚪 LOGOUT
        InkWell(
  borderRadius: BorderRadius.circular(14),
  onTap: () async {
    // Stocker le context localement pour le showDialog
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext, // OK, context avant async
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    // ✅ Vérifier si le widget est toujours monté avant d'utiliser context
    if (confirm == true && currentContext.mounted) {
      await context.read<AuthProvider>().logout();
      if (currentContext.mounted) {
        Navigator.of(currentContext)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: const Text(
      'Se déconnecter',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
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

 void _openThemePicker(BuildContext context) {
  final parentContext = context; // 🔥 CONTEXT STABLE

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ThemePicker(parentContext: parentContext),
  );
}


  String _themeLabel(String? theme) {
    switch (theme) {
      case 'dark_minimal':
        return 'Dark minimal';
      case 'clean_light':
        return 'Clean light';
      default:
        return 'Classique';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ================= THEME PICKER =================

class _ThemePicker extends StatelessWidget {
  final BuildContext parentContext;

  const _ThemePicker({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Thème de la carte',
            style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          _item(context, card, 'default', 'Classique'),
          _item(context, card, 'clean_light', 'Clean light'),
          _item(context, card, 'dark_minimal', 'Dark minimal'),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    CardProvider card,
    String value,
    String label,
  ) {
    final selected = card.theme == value;

    return ListTile(
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () async {
        try {
          await card.updateTheme(value);
          if (context.mounted) Navigator.pop(context);
        } on ThemeForbiddenException catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
           _showProDialog(parentContext, e.message);
          }
        }
      },

    );
  }


  void _showProDialog(BuildContext context, String message) {
 showDialog(
  context: context,
  useRootNavigator: true,
  builder: (_) => AlertDialog(
      title: const Text('Fonction premium ✨'),
      content: Text(message),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
       TextButton(
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Plus tard'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true)
                .pushNamed('/upgrade');
          },
          child: const Text('Passer PRO'),
        ),

      ],
    ),
  );
}

}

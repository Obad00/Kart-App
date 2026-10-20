import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/notification_prefs.dart';
import '../../../core/services/push_notification_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Écran "Notifications" des Réglages — jusqu'ici l'entrée existait dans le
/// menu mais ne faisait littéralement rien (onTap vide). Ici, un vrai
/// interrupteur qui enregistre/supprime le token push côté backend, avec la
/// préférence persistée pour ne pas être silencieusement réactivée à la
/// prochaine connexion (voir AuthProvider.loadMe()).
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enabled = true;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationPrefs.isEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _enabled = value;
      _busy = true;
    });

    await NotificationPrefs.setEnabled(value);
    if (value) {
      await PushNotificationService.registerToken();
    } else {
      await PushNotificationService.deleteToken();
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }

  bool _reminderBusy = false;

  /// Rappels pour compléter son profil : préférence enregistrée sur le
  /// serveur (PUT /me/preferences).
  Future<void> _toggleReminders(bool value) async {
    setState(() => _reminderBusy = true);
    final ok = await context.read<AuthProvider>().setProfileReminders(value);
    if (!mounted) return;
    setState(() => _reminderBusy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Impossible d'enregistrer ce réglage. Réessayez."),
      ));
    }
  }

  Widget _settingCard(
    ColorScheme colors, {
    required Key key,
    required String title,
    required String subtitle,
    required bool value,
    required bool busy,
    required ValueChanged<bool>? onChanged,
  }) {
    return Opacity(
      opacity: onChanged == null && !busy ? 0.5 : 1,
      child: Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: colors.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            busy
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reminders = context.watch<AuthProvider>().user?.profileRemindersEnabled ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _settingCard(
                  colors,
                  key: const Key('push-notifications'),
                  title: 'Notifications push',
                  subtitle: 'Nouvelles demandes de mise en relation, réponses à vos '
                      'demandes, et autres activités sur votre compte KART.',
                  value: _enabled,
                  busy: _busy,
                  onChanged: _toggle,
                ),
                const SizedBox(height: 12),
                Text(
                  _enabled
                      ? 'Vous recevrez des notifications sur cet appareil.'
                      : 'Vous ne recevrez plus de notifications sur cet appareil.',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 20),
                // Ces rappels sont des notifications push : sans elles, ils
                // ne peuvent pas arriver, d'où l'interrupteur grisé.
                _settingCard(
                  colors,
                  key: const Key('profile-reminders'),
                  title: 'Rappels pour compléter mon profil',
                  subtitle: _enabled
                      ? 'Au plus 3 rappels, seulement tant que votre profil est peu rempli.'
                      : "Activez d'abord les notifications push.",
                  value: reminders,
                  busy: _reminderBusy,
                  onChanged: _enabled ? _toggleReminders : null,
                ),
              ],
            ),
    );
  }
}

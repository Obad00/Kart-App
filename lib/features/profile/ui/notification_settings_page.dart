import 'package:flutter/material.dart';
import '../../../core/services/notification_prefs.dart';
import '../../../core/services/push_notification_service.dart';

/// Écran "Notifications" des Réglages — jusqu'ici l'entrée existait dans le
/// menu mais ne faisait littéralement rien (onTap vide). Ici, un vrai
/// interrupteur qui enregistre/supprime le token push côté backend, avec la
/// préférence persistée pour ne pas être silencieusement réactivée à la
/// prochaine connexion (voir AuthProvider.loadMe()).
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
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
                              'Notifications push',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nouvelles demandes de mise en relation, réponses à vos '
                              'demandes, et autres activités sur votre compte KART.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(value: _enabled, onChanged: _toggle),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _enabled
                      ? 'Vous recevrez des notifications sur cet appareil.'
                      : 'Vous ne recevrez plus de notifications sur cet appareil.',
                  style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.45)),
                ),
              ],
            ),
    );
  }
}

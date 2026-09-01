import 'package:shared_preferences/shared_preferences.dart';

/// Préférence locale "notifications push activées" — persistée pour que le
/// choix de l'utilisateur survive à une reconnexion. Sans ça, désactiver les
/// notifications dans Réglages n'aurait aucun effet durable : AuthProvider
/// ré-enregistre automatiquement le token push à chaque connexion réussie.
class NotificationPrefs {
  static const _key = 'push_notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}

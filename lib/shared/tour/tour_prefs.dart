import 'package:shared_preferences/shared_preferences.dart';

/// Petit utilitaire partagé pour les guides (coach marks) affichés une seule
/// fois par écran, à la première visite — chaque écran a sa propre clé, donc
/// voir le guide d'un écran ne dispense pas de voir celui d'un autre.
///
/// Le bouton "Passer" (affiché sur chaque guide, cf. globalTooltipActions
/// dans main.dart) ferme juste l'overlay en cours — comme le drapeau "vu"
/// est déjà posé au démarrage du guide (pas à la fin), passer ou terminer le
/// guide a le même effet : il ne se redéclenche plus après.
class TourPrefs {
  static Future<bool> hasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tour_seen_$key') ?? false;
  }

  static Future<void> markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_seen_$key', true);
  }

  /// Pour "Revoir les guides" dans Réglages : oublie tous les guides déjà
  /// vus (bottom nav + tous les écrans), pour que l'app les remontre au fil
  /// de la navigation, comme au premier lancement.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('tour_seen_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}

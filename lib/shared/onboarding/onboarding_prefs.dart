import 'package:shared_preferences/shared_preferences.dart';

/// Drapeau "à consommer une seule fois" posé quand la carte digitale vient
/// d'être créée automatiquement (juste après vérification de l'email, cf.
/// EmailVerificationPage) — MyDigitalCardPage le consulte à l'arrivée pour
/// savoir s'il faut proposer, après quelques secondes, de compléter poste
/// et entreprise. Même esprit que TourPrefs (guides), mais concept distinct
/// : celui-ci ne s'affiche qu'une fois, jamais reproposé même via "Revoir
/// les guides".
class OnboardingPrefs {
  static const _key = 'pending_job_company_prompt';

  static Future<void> markPendingJobCompanyPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Lit puis efface immédiatement le drapeau — un seul appelant peut donc
  /// jamais recevoir `true` deux fois de suite.
  static Future<bool> consumePendingJobCompanyPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_key) ?? false;
    if (pending) {
      await prefs.remove(_key);
    }
    return pending;
  }
}

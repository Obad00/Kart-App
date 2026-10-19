import '../auth/models/user.dart';
import '../../shared/utils/jobmatch_access.dart';

/// Où ouvrir l'app au toucher d'un rappel de complétion (notification
/// `profile_reminder`) : l'onglet Profil, puis l'élément manquant. On
/// préfère l'élément suivant ACTUEL (le profil a pu bouger depuis l'envoi),
/// sinon celui de la notification.
({int tab, String item}) profileReminderTarget(Map<String, dynamic> data, User? user) {
  final profileTab = canAccessJobMatch(user?.plan) ? 4 : 3;
  final item = user?.profileScore?.next?.key ?? data['item']?.toString() ?? '';
  return (tab: profileTab, item: item);
}

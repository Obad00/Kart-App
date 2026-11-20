import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/auth/models/user.dart';
import 'package:kart_app/features/profile_completion/profile_reminder_target.dart';
import 'package:kart_app/shared/utils/jobmatch_access.dart';

User _user(String plan, {String? next}) => User.fromJson({
      'id': 1, 'firstname': 'Awa', 'lastname': 'Diop', 'email': 'awa.diop@example.test', 'plan': plan,
      if (next != null)
        'profile_score': {'score': 30, 'criteria': [], 'next': {'key': next, 'label': next, 'weight': 10}},
    });

void main() {
  test("JobMatch fermé : barre à 4 onglets, Profil en position 3 pour tous les plans", () {
    for (final plan in ['free', 'pro', 'enterprise']) {
      expect(canAccessJobMatch(plan), isFalse);
      expect(profileReminderTarget({'item': 'photo'}, _user(plan)).tab, 3);
    }
  });

  test("l'élément suivant actuel l'emporte sur celui de la notification", () {
    expect(profileReminderTarget({'item': 'photo'}, _user('pro', next: 'bio')).item, 'bio');
    expect(profileReminderTarget({'item': 'photo'}, _user('pro')).item, 'photo');
    expect(profileReminderTarget({}, null).item, '');
  });
}

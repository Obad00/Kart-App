import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/profile_completion/model/profile_completion_model.dart';
import 'package:kart_app/features/public_card_settings/models/public_card_settings.dart';

void main() {
  test('TikTok est lu et renvoyé par le formulaire du profil', () {
    final model = ProfileCompletionModel.fromJson({
      'tiktok': 'https://www.tiktok.com/@awa.diop',
      'activated_fields': ['tiktok'],
    });

    expect(model.tiktok, 'https://www.tiktok.com/@awa.diop');
    expect(model.toJson()['tiktok'], 'https://www.tiktok.com/@awa.diop');
  });

  test("« Réseaux sociaux » pilote aussi TikTok, juste après Instagram", () {
    expect(PublicCardSettings.fieldsOf['socials'],
        ['linkedin', 'instagram', 'tiktok', 'facebook', 'github']);
  });
}

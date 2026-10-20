import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/profile_completion/model/profile_completion_model.dart';

void main() {
  test("« Apparaître dans Explorer » est lu et renvoyé, séparé de « carte publique »", () {
    final model = ProfileCompletionModel.fromJson({'is_public': true, 'listed_in_directory': false});

    expect(model.isPublic, isTrue);
    expect(model.listedInDirectory, isFalse);

    model.listedInDirectory = true;
    expect(model.toJson()['listed_in_directory'], isTrue);
    expect(model.toJson()['is_public'], isTrue);
  });

  test('serveur plus ancien (champ absent) : pas dans l\'annuaire', () {
    expect(ProfileCompletionModel.fromJson({'is_public': true}).listedInDirectory, isFalse);
  });
}

// Mêmes seuils que le backend (App\Support\ColorContrast) : référence, le
// logo CMAS — bleu marine illisible sur la carte sombre, or bien lisible.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/shared/utils/color_contrast.dart';

const _navy = Color(0xFF0B2B5B);
const _gold = Color(0xFFC99A2E);

void main() {
  test('le rapport de contraste suit WCAG', () {
    expect(
      ColorContrast.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    // Mêmes valeurs que celles calculées par le serveur.
    expect(ColorContrast.ratio(_navy, ColorContrast.darkBackground),
        closeTo(1.25, 0.02));
    expect(ColorContrast.ratio(_gold, ColorContrast.darkBackground),
        closeTo(6.75, 0.02));
  });

  test('le marine est peu lisible sur la carte, l\'or et le bleu KART non', () {
    expect(ColorContrast.isReadableOnCard(_navy), isFalse);
    expect(ColorContrast.isReadableOnCard(_gold), isTrue);
    // Bleu par défaut de l'app : 3,4:1, au-dessus du seuil d'alerte.
    expect(ColorContrast.isReadableOnCard(const Color(0xFF2563EB)), isTrue);
  });

  test('« Ajuster » éclaircit jusqu\'à 4,5:1 en gardant la teinte', () {
    final adjusted = ColorContrast.adjustForCard(_navy);

    expect(
      ColorContrast.ratio(adjusted, ColorContrast.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      HSLColor.fromColor(adjusted).hue,
      closeTo(HSLColor.fromColor(_navy).hue, 3),
    );
    // Une couleur déjà bien lisible n'est pas modifiée.
    expect(ColorContrast.adjustForCard(_gold), _gold);
  });
}

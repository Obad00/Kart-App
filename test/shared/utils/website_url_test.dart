import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/shared/utils/website_url.dart';

void main() {
  test('un site saisi sans protocole est complété en https://', () {
    expect(completeWebsiteUrl('monsite.com'), 'https://monsite.com');
    expect(completeWebsiteUrl('  www.monsite.com/portfolio '),
        'https://www.monsite.com/portfolio');
  });

  test('un protocole déjà présent est gardé, un champ vide reste vide', () {
    expect(completeWebsiteUrl('https://monsite.com'), 'https://monsite.com');
    expect(completeWebsiteUrl('http://monsite.com'), 'http://monsite.com');
    expect(completeWebsiteUrl('   '), '');
  });
}

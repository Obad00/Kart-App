import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/shared/utils/plural.dart';

void main() {
  test('0 et 1 au singulier, au-delà le pluriel', () {
    expect(plural(0, 'highlight'), '0 highlight');
    expect(plural(1, 'highlight'), '1 highlight');
    expect(plural(2, 'highlight'), '2 highlights');
    expect(plural(12, 'contact'), '12 contacts');
  });

  test('pluriel irrégulier', () {
    expect(plural(1, 'travail', 'travaux'), '1 travail');
    expect(plural(3, 'travail', 'travaux'), '3 travaux');
  });
}

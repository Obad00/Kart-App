import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/nfc_card/widgets/nfc_order_sheet.dart';

Widget _wrap(Future<String?> Function(String phone) onSubmit) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: NfcOrderSheet(
          onSubmit: ({required phone, required address, notes}) =>
              onSubmit(phone),
        ),
      ),
    );

Finder _phoneInput() => find.descendant(
      of: find.byKey(const ValueKey('nfc-order-phone')),
      matching: find.byType(TextField),
    );

void main() {
  testWidgets('rejects invalid numbers before submitting', (tester) async {
    var submitted = false;
    await tester.pumpWidget(_wrap((_) async {
      submitted = true;
      return null;
    }));

    await tester.enterText(find.byType(TextFormField).first, 'Dakar');
    await tester.enterText(_phoneInput(), '123');
    await tester.tap(find.text('Envoyer ma commande'));
    await tester.pumpAndSettle();

    expect(submitted, isFalse);
    expect(
      find.text('Ce numéro semble invalide. Vérifiez le pays et le numéro.'),
      findsOneWidget,
    );
  });

  testWidgets('submits a valid local number in international format',
      (tester) async {
    String? submittedPhone;
    await tester.pumpWidget(_wrap((phone) async {
      submittedPhone = phone;
      return 'Keep form open for test';
    }));

    await tester.enterText(find.byType(TextFormField).first, 'Dakar');
    await tester.enterText(_phoneInput(), '770000000');
    await tester.tap(find.text('Envoyer ma commande'));
    await tester.pumpAndSettle();

    expect(submittedPhone, '+221770000000');
  });
}

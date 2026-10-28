import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/core/ui/feedback/feedback_overlay.dart';

/// Toast de succès : inséré dans l'Overlay, hors de tout Scaffold. Sans
/// Material au-dessus, ses textes prenaient le style de secours de Flutter
/// (double soulignement jaune) ; et greenAccent se voyait mal en thème clair.
Future<void> _showToast(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => FeedbackOverlay.showSuccess(context, title: 'Carte enregistrée', subtitle: 'Vos modifications sont en ligne.'),
          child: const Text('Afficher'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Afficher'));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('les textes du toast ont un Material au-dessus (pas de style de secours)', (tester) async {
    await _showToast(tester, AppTheme.light());

    final style = tester.widget<DefaultTextStyle>(
      find.ancestor(of: find.text('Carte enregistrée'), matching: find.byType(DefaultTextStyle)).first,
    ).style;
    expect(style.decoration, isNot(TextDecoration.underline));
    expect(find.ancestor(of: find.text('Carte enregistrée'), matching: find.byType(Material)), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });

  Color iconColor(WidgetTester tester) => tester.widget<Icon>(find.byIcon(Icons.check_circle)).color!;

  testWidgets('icône de succès : vert soutenu en thème clair', (tester) async {
    await _showToast(tester, AppTheme.light());
    expect(iconColor(tester), Colors.green.shade600);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('icône de succès : greenAccent en thème sombre', (tester) async {
    await _showToast(tester, AppTheme.dark());
    expect(iconColor(tester), Colors.greenAccent);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
  });
}

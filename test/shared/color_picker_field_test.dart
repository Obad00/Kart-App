// Écran « Personnaliser ma carte » : le champ couleur reste identique, et
// on y ajoute seulement, quand le logo a des couleurs, une ligne « Couleurs
// de votre logo » (badge « Suggérée », aucune présélection), plus une alerte
// discrète quand la couleur choisie manque de contraste.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/shared/utils/color_contrast.dart';
import 'package:kart_app/shared/widgets/color_picker_field.dart';

const _navy = Color(0xFF0B2B5B);
const _gold = Color(0xFFC99A2E);
const _kartBlue = Color(0xFF2563EB); // couleur par défaut de l'app
const _warning = 'Peu lisible sur votre carte publique';

Finder _logoSwatch(Color color) {
  final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
  return find.byKey(ValueKey('logo-color-#$hex'));
}

Finder _logoSwatches() => find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('logo-color-'),
    );

Future<List<Color>> _pump(
  WidgetTester tester, {
  Color initial = _kartBlue,
  List<Color> logoColors = const [],
  Color? suggested,
  String? notice,
  bool warn = true,
  bool initialIsDefault = false,
}) async {
  final changes = <Color>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ColorPickerField(
              label: 'Couleur d\'accent',
              initialColor: initial,
              onColorChanged: changes.add,
              logoColors: logoColors,
              suggestedColor: suggested,
              logoNotice: notice,
              warnWhenUnreadable: warn,
              initialIsDefault: initialIsDefault,
            ),
          ),
        ),
      ),
    ),
  );
  return changes;
}

void main() {
  testWidgets('sans couleurs de logo, le champ est celui d\'avant',
      (tester) async {
    await _pump(tester);

    expect(find.text('Couleurs de votre logo'), findsNothing);
    expect(find.text('Suggérée'), findsNothing);
    expect(_logoSwatches(), findsNothing);
    expect(find.text(_warning), findsNothing);
    // La pipette, le champ hex et la palette sont toujours là.
    expect(find.byIcon(Icons.colorize_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('les couleurs du logo sont proposées, sans présélection',
      (tester) async {
    final changes = await _pump(
      tester,
      logoColors: const [_navy, _gold],
      suggested: _gold,
    );

    expect(find.text('Couleurs de votre logo'), findsOneWidget);
    expect(_logoSwatches(), findsNWidgets(2));
    expect(find.text('Suggérée'), findsOneWidget);

    // Le badge est sous la pastille or, pas sous la marine.
    final badge = tester.getCenter(find.text('Suggérée'));
    expect(badge.dx, closeTo(tester.getCenter(_logoSwatch(_gold)).dx, 1));

    // Aucune présélection : la couleur n'a pas bougé, aucune pastille du
    // logo n'est cochée.
    expect(changes, isEmpty);
    expect(
      find.descendant(of: _logoSwatches(), matching: find.byIcon(Icons.check)),
      findsNothing,
    );

    // Toucher une pastille du logo la sélectionne, comme dans la palette.
    await tester.tap(_logoSwatch(_gold));
    await tester.pumpAndSettle();
    expect(changes, [_gold]);
    expect(
      find.descendant(
        of: _logoSwatch(_gold),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'si aucune couleur du logo n\'est lisible, la suggérée est une pastille en plus',
      (tester) async {
    final lightened = ColorContrast.adjustForCard(_navy);
    await _pump(tester, logoColors: const [_navy], suggested: lightened);

    expect(_logoSwatches(), findsNWidgets(2));
    final badge = tester.getCenter(find.text('Suggérée'));
    expect(badge.dx, closeTo(tester.getCenter(_logoSwatch(lightened)).dx, 1));
  });

  testWidgets('jamais plus de 6 pastilles pour le logo', (tester) async {
    await _pump(
      tester,
      logoColors: const [
        Color(0xFFE11D48),
        Color(0xFF16A34A),
        Color(0xFF2563EA),
        Color(0xFFF59E0B),
        Color(0xFF9333EA),
        Color(0xFF0891B2),
        Color(0xFFDB2777),
      ],
      suggested: const Color(0xFFFFFFFF),
    );

    expect(_logoSwatches(), findsNWidgets(6)); // 5 du logo + la suggérée
  });

  testWidgets('le message « Logo enregistré » s\'affiche au-dessus de la ligne',
      (tester) async {
    await _pump(
      tester,
      logoColors: const [_gold],
      suggested: _gold,
      notice: 'Logo enregistré',
    );

    final notice = tester.getTopLeft(find.text('Logo enregistré'));
    final title = tester.getTopLeft(find.text('Couleurs de votre logo'));
    expect(notice.dy, lessThan(title.dy));
  });

  testWidgets('une couleur peu lisible affiche l\'alerte, « Ajuster » la corrige',
      (tester) async {
    final changes = await _pump(
      tester,
      logoColors: const [_navy, _gold],
      suggested: _gold,
    );
    expect(find.text(_warning), findsNothing);

    await tester.tap(_logoSwatch(_navy));
    await tester.pumpAndSettle();
    expect(find.text(_warning), findsOneWidget);
    expect(find.text('Ajuster'), findsOneWidget);

    await tester.tap(find.text('Ajuster'));
    await tester.pumpAndSettle();

    expect(find.text(_warning), findsNothing);
    expect(changes.last, ColorContrast.adjustForCard(_navy));
    expect(
      ColorContrast.ratio(changes.last, ColorContrast.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('une carte déjà enregistrée en couleur sombre est signalée à l\'ouverture',
      (tester) async {
    await _pump(tester, initial: _navy);

    expect(find.text(_warning), findsOneWidget);
  });

  testWidgets('jamais d\'alerte pour la couleur par défaut non modifiée',
      (tester) async {
    // Même avec une couleur par défaut qui serait sombre : tant que
    // l'utilisateur n'a rien choisi, on ne lui reproche rien.
    await _pump(tester, initial: _navy, initialIsDefault: true);
    expect(find.text(_warning), findsNothing);

    await _pump(tester, initial: _kartBlue, initialIsDefault: true);
    expect(find.text(_warning), findsNothing);
  });

  testWidgets('l\'alerte est désactivée hors de la personnalisation de carte',
      (tester) async {
    // Ex. couleur d'entreprise à la création : comportement inchangé.
    await _pump(tester, initial: _navy, warn: false);

    expect(find.text(_warning), findsNothing);
  });
}

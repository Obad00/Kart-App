// Remonté sur l'écran Carte en mode sombre : les initiales « PS » de
// l'avatar étaient écrites dans la couleur d'accent de la carte (bleu
// marine) sur un rond de cette même couleur à 10 %, posé sur un fond noir —
// illisibles. AvatarInitials garantit au moins 4,5:1 avec le fond du rond,
// en clair comme en sombre, quelle que soit la couleur d'accent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/shared/utils/color_contrast.dart';
import 'package:kart_app/shared/widgets/avatar_initials.dart';

const _navy = Color(0xFF0B2B5B);
const _gold = Color(0xFFC99A2E);
const _yellow = Color(0xFFFACC15);

/// Rend l'avatar de l'en-tête de l'écran Carte : rond = accent à 10 % sur
/// le fond de la page, initiales dans l'accent. Renvoie le contraste obtenu
/// entre les initiales et le fond réel du rond.
Future<({double ratio, Color text})> _pumpHeaderAvatar(
  WidgetTester tester, {
  required Color accent,
  required bool dark,
}) async {
  late Color background;

  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            background = ColorContrast.composite(
              accent.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            );
            return Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: AvatarInitials(
                  initials: 'PS',
                  accent: accent,
                  background: background,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  final text = tester.widget<Text>(find.text('PS')).style!.color!;
  return (ratio: ColorContrast.ratio(text, background), text: text);
}

void main() {
  testWidgets('accent marine en thème sombre : les initiales restent lisibles',
      (tester) async {
    // Avant le correctif : marine sur un rond marine à 10 % sur fond noir.
    final before = ColorContrast.ratio(
      _navy,
      ColorContrast.composite(
        _navy.withValues(alpha: 0.1),
        AppTheme.dark().scaffoldBackgroundColor,
      ),
    );
    expect(before, lessThan(2), reason: 'le cas signalé était bien illisible');

    final result = await _pumpHeaderAvatar(tester, accent: _navy, dark: true);

    expect(result.ratio, greaterThanOrEqualTo(4.5));
    // Toujours un bleu : la teinte de l'accent est conservée.
    expect(
      HSLColor.fromColor(result.text).hue,
      closeTo(HSLColor.fromColor(_navy).hue, 3),
    );
    expect(result.text, isNot(_navy));
  });

  testWidgets('accent marine en thème clair : inchangé, il y est déjà lisible',
      (tester) async {
    final result = await _pumpHeaderAvatar(tester, accent: _navy, dark: false);

    expect(result.text, _navy);
    expect(result.ratio, greaterThanOrEqualTo(4.5));
  });

  testWidgets('accent jaune en thème clair : assombri jusqu\'à être lisible',
      (tester) async {
    final result =
        await _pumpHeaderAvatar(tester, accent: _yellow, dark: false);

    expect(result.ratio, greaterThanOrEqualTo(4.5));
    expect(result.text, isNot(_yellow));
  });

  testWidgets('accent or en thème sombre : inchangé', (tester) async {
    final result = await _pumpHeaderAvatar(tester, accent: _gold, dark: true);

    expect(result.text, _gold);
  });

  test('toutes les couleurs de la palette donnent au moins 4,5:1', () {
    // Les 20 couleurs proposées dans « Personnaliser ma carte », plus les
    // extrêmes, sur les fonds d'avatar de l'app en clair et en sombre.
    const accents = [
      Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF0EA5E9),
      Color(0xFF06B6D4), Color(0xFF14B8A6), Color(0xFF10B981),
      Color(0xFF22C55E), Color(0xFF84CC16), Color(0xFFEAB308),
      Color(0xFFF59E0B), Color(0xFFF97316), Color(0xFFEF4444),
      Color(0xFFEC4899), Color(0xFFD946EF), Color(0xFFA855F7),
      Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF000000),
      Color(0xFF374151), Color(0xFF6B7280), Color(0xFFFFFFFF),
      _navy, Color(0xFF002842),
    ];
    final pages = [
      AppTheme.dark().scaffoldBackgroundColor,
      AppTheme.light().scaffoldBackgroundColor,
      AppTheme.dark().colorScheme.surface,
      AppTheme.light().colorScheme.surface,
      const Color(0xFF1E293B), // fond de l'avatar, carte publique sombre
      const Color(0xFFEFF6FF), // idem, clair
    ];

    for (final accent in accents) {
      for (final page in pages) {
        for (final background in [
          page,
          ColorContrast.composite(accent.withValues(alpha: 0.1), page),
        ]) {
          final text = ColorContrast.readableOn(accent, background);
          expect(
            ColorContrast.ratio(text, background),
            greaterThanOrEqualTo(4.5),
            reason: 'accent $accent sur $background',
          );
        }
      }
    }
  });

  test('readableOn ne touche pas une couleur déjà lisible', () {
    const white = Color(0xFFFFFFFF);
    expect(ColorContrast.readableOn(_navy, white), _navy);
    expect(
      ColorContrast.readableOn(const Color(0xFF000000), const Color(0xFF000000)),
      white,
    );
  });
}

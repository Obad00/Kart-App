// Retouches d'interface : accent lisible dans les deux thèmes, nom jamais
// coupé au milieu d'un mot, menu verre.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/shared/utils/color_contrast.dart';
import 'package:kart_app/shared/utils/company_color_helper.dart';
import 'package:kart_app/shared/widgets/fit_words_text.dart';
import 'package:kart_app/shared/widgets/glass_menu.dart';
import 'package:kart_app/shared/widgets/glass_sheet.dart';
import 'package:provider/provider.dart';

/// Carte dont on choisit les couleurs, sans réseau.
class _Card extends CardProvider {
  _Card({this.accent, this.accentLight, this.brandColor});

  final String? accent;
  final String? accentLight;
  final String? brandColor;

  @override
  String? get accentColor => accent;
  @override
  String? get accentColorLight => accentLight;
  @override
  String? get companyPrimaryColor => brandColor;
}

/// Couleurs (texte, fond plein) que voit un écran avec cette carte et ce thème.
Future<(Color, Color)> _colors(WidgetTester tester, CardProvider card, {required bool dark}) async {
  late Color ink;
  late Color fill;
  await tester.pumpWidget(ChangeNotifierProvider<CardProvider>.value(
    value: card,
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(builder: (context) {
        ink = context.companyColor;
        fill = context.companyFill;
        return const SizedBox();
      }),
    ),
  ));
  return (ink, fill);
}

const _darkBg = Color(0xFF2A2A2A);
const _lightBg = Color(0xFFF5F4F0);

void main() {
  group('Accent lisible', () {
    testWidgets('accent foncé en thème sombre : texte éclairci, fond plein intact', (tester) async {
      final (ink, fill) = await _colors(tester, _Card(accent: '#002842'), dark: true);
      expect(ColorContrast.ratio(ink, _darkBg), greaterThanOrEqualTo(ColorContrast.textRatio));
      expect(fill, const Color(0xFF002842));
      // Même teinte, seulement éclaircie.
      expect(HSLColor.fromColor(ink).hue, closeTo(HSLColor.fromColor(fill).hue, 1));
    });

    testWidgets('accent très clair en thème clair : texte assombri', (tester) async {
      final (ink, _) = await _colors(tester, _Card(accent: '#F5E663'), dark: false);
      expect(ColorContrast.ratio(ink, _lightBg), greaterThanOrEqualTo(ColorContrast.textRatio));
    });

    testWidgets('thème clair : la variante du serveur (accent_color_light) passe en premier', (tester) async {
      final (ink, fill) = await _colors(tester, _Card(accent: '#F5E663', accentLight: '#7A6A00'), dark: false);
      expect(fill, const Color(0xFF7A6A00));
      expect(ColorContrast.ratio(ink, _lightBg), greaterThanOrEqualTo(ColorContrast.textRatio));
    });

    testWidgets('accent déjà lisible : inchangé', (tester) async {
      final (ink, _) = await _colors(tester, _Card(accent: '#60A5FA'), dark: true);
      expect(ink, const Color(0xFF60A5FA));
    });

    testWidgets('la couleur d\'entreprise suit la même règle', (tester) async {
      final (ink, fill) = await _colors(tester, _Card(accent: '#F5E663', brandColor: '#002842'), dark: true);
      expect(fill, const Color(0xFF002842));
      expect(ColorContrast.ratio(ink, _darkBg), greaterThanOrEqualTo(ColorContrast.textRatio));
    });
  });

  group('Nom sur 2 lignes, jamais coupé au milieu d\'un mot', () {
    const style = TextStyle(fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: 0.4);

    double size(String text, double width) =>
        FitWordsText.fittingSize(text, style, width, minFontSize: 9, maxLines: 2);

    for (final name in ['MAME DIARRA BOUSSO NDIAYE', 'ABDOULAYE DIACK', 'AWA NDIAYEMBOUPDIALLO']) {
      test(name, () {
        const width = 160.0;
        final fontSize = size(name, width);
        final painter = TextPainter(
          text: TextSpan(text: name, style: style.copyWith(fontSize: fontSize)),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: width);
        expect(painter.didExceedMaxLines, isFalse);
        // Chaque mot tient entier sur une ligne.
        for (final word in name.split(' ')) {
          final w = TextPainter(
            text: TextSpan(text: word, style: style.copyWith(fontSize: fontSize)),
            textDirection: TextDirection.ltr,
          )..layout();
          expect(w.width, lessThanOrEqualTo(width), reason: word);
        }
      });
    }

    test('sans maxLines, comportement inchangé (seul le mot le plus long compte)', () {
      expect(FitWordsText.fittingSize('ABDOULAYE DIACK', style, 1000, minFontSize: 9), 23);
    });
  });

  group('Menu verre', () {
    testWidgets('ouvre ses entrées sur verre et renvoie le choix', (tester) async {
      String? chosen;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: GlassMenuButton<String>(
              tooltip: "Plus d'options",
              onSelected: (v) => chosen = v,
              itemBuilder: (_) => const [
                GlassMenuItem(value: 'export', icon: Icons.file_upload_outlined, title: 'Exporter'),
                GlassMenuItem(value: 'delete', icon: Icons.delete_outline_rounded, title: 'Supprimer', destructive: true),
              ],
              child: const Icon(Icons.more_horiz_rounded),
            ),
          ),
        ),
      ));
      await tester.tap(find.byTooltip("Plus d'options"));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSheet), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(chosen, 'delete');
      expect(find.text('Exporter'), findsNothing);
    });
  });
}

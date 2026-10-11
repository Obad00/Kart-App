import 'package:flutter/material.dart';

/// Définitions visuelles de la carte publique côté app — LE seul fichier
/// où elles sont écrites. Mêmes valeurs que `CardVisual.vue` et
/// `PublicCard.vue` côté site : ne pas modifier l'un sans l'autre. Utilisées par l'aperçu,
/// les vignettes de disposition et les vignettes de style.
///
/// Référence : le site EN LIGNE (kart-vue-project, main 7e566a0).
abstract final class PublicCardStyles {
  /// Couleur d'accent quand aucune n'est choisie (or KART).
  static const Color defaultAccent = Color(0xFFC99A2E);

  /// Fond des initiales (photo absente) et des initiales d'entreprise.
  static const Color initialsBackground = Color(0xFF0E2A57);

  /// Pastilles proposées, dans l'ordre de la maquette.
  static const List<Color> accentPresets = [
    Color(0xFFC99A2E),
    Color(0xFF4F8EF7),
    Color(0xFF4ADE80),
    Color(0xFFE5484D),
    Color(0xFFA78BFA),
    Color(0xFFE9E6DF),
  ];

  // ── Visuel « carte physique » ────────────────────────────────────────
  // Valeurs de CardVisual.vue du site en ligne (main 7e566a0) : l'aperçu
  // de l'app dessine la même carte que la page publique.
  static const double cardRadius = 20;

  /// Inclinaison de la carte glissée derrière (−4°), en radians.
  static const double backCardAngle = -4 * 3.141592653589793 / 180;

  /// Couleurs d'un style de carte, pour un accent donné.
  static PublicCardLook cardLook(String style, Color accent) {
    final on = onColor(accent);
    return switch (style) {
      // Dégradé : la carte est de la couleur d'accent ; derrière, la même
      // couleur assombrie.
      'gradient' => PublicCardLook(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, Color.lerp(accent, Colors.black, 0.38)!],
          ),
          text: on,
          muted: on.withValues(alpha: 0.72),
          border: on.withValues(alpha: 0.14),
          back: Color.lerp(accent, Colors.black, 0.55)!,
          avatarBackground: on,
          avatarText: accent,
        ),
      // Marine : bleu nuit, quelle que soit la couleur d'accent.
      'marine' => PublicCardLook(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2B5B), Color(0xFF061A38)],
          ),
          text: Colors.white,
          muted: Colors.white.withValues(alpha: 0.68),
          border: Colors.white.withValues(alpha: 0.14),
          back: accent,
          avatarBackground: accent,
          avatarText: on,
        ),
      // Mat : noir uni.
      _ => PublicCardLook(
          gradient: const LinearGradient(
            colors: [Color(0xFF121213), Color(0xFF121213)],
          ),
          text: const Color(0xFFF4F1EA),
          muted: const Color(0xFFF4F1EA).withValues(alpha: 0.62),
          border: Colors.white.withValues(alpha: 0.1),
          back: accent,
          avatarBackground: accent,
          avatarText: on,
        ),
    };
  }

  // ── Couleurs ─────────────────────────────────────────────────────────
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
  }

  /// Noir ou blanc : le plus lisible des deux posé sur [color] (texte d'un
  /// bouton plein). Même règle que le serveur (`on_color`).
  static Color onColor(Color color) =>
      contrast(Colors.black, color) >= contrast(Colors.white, color)
          ? Colors.black
          : Colors.white;

  /// Couleur d'accent utilisée comme TEXTE ou ICÔNE : la même teinte,
  /// assombrie (fond clair) ou éclaircie (fond sombre) juste assez pour
  /// atteindre 4,5:1 sur chacun des [backgrounds]. Renvoyée telle quelle si
  /// elle est déjà lisible. Même calcul que `readableAccent` côté site ;
  /// les boutons pleins, eux, gardent l'accent d'origine.
  static Color readableAccent(
    Color accent,
    List<Color> backgrounds, {
    double minimum = 4.5,
  }) {
    bool readable(Color c) =>
        backgrounds.every((background) => contrast(c, background) >= minimum);
    if (readable(accent)) return accent;

    final target = backgrounds.first.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    for (var step = 1; step <= 40; step++) {
      final mixed = Color.lerp(accent, target, step / 40)!;
      if (readable(mixed)) return mixed;
    }
    return target;
  }

  static String toHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// Couleurs du visuel « carte physique » pour un style donné.
class PublicCardLook {
  const PublicCardLook({
    required this.gradient,
    required this.text,
    required this.muted,
    required this.border,
    required this.back,
    required this.avatarBackground,
    required this.avatarText,
  });

  final LinearGradient gradient;
  final Color text;
  final Color muted;
  final Color border;

  /// Carte glissée derrière.
  final Color back;
  final Color avatarBackground;
  final Color avatarText;
}

/// Couleurs de la PAGE publique par thème — celles du site en ligne
/// (PALETTES de PublicCard.vue, main 7e566a0).
class PublicPagePalette {
  const PublicPagePalette._(this.background, this.surface, this.line, this.text);

  static const dark = PublicPagePalette._(
      Color(0xFF0B0B0C), Color(0xFF151517), Color(0xFF2A2A2D), Color(0xFFE9E6DF));
  static const light = PublicPagePalette._(
      Color(0xFFF4F1EA), Color(0xFFFFFFFF), Color(0xFFE2DDD1), Color(0xFF121212));

  static PublicPagePalette of(String theme) => theme == 'light' ? light : dark;

  final Color background;
  final Color surface;
  final Color line;
  final Color text;

  /// Texte secondaire : le texte à 62 % sur le fond, comme sur le site.
  Color get muted => Color.lerp(background, text, 0.62)!;
}

/// Couleurs des dispositions Bento et Éditorial par thème — celles du site
/// en ligne (PALETTES de publicCardNext/theme.js, main 83cad2d).
class PublicNextPalette {
  const PublicNextPalette._({
    required this.background,
    required this.surface,
    required this.line,
    required this.strong,
    required this.text,
    required this.soft,
    required this.muted,
    required this.faint,
    required this.inverseBackground,
    required this.inverseText,
    required this.shareLine,
    required this.logoLine,
    required this.whatsapp,
    required this.stickyShadow,
  });

  static const dark = PublicNextPalette._(
    background: Color(0xFF0B0B0C),
    surface: Color(0xFF151517),
    line: Color(0xFF2A2A2D),
    strong: Color(0xFFFFFFFF),
    text: Color(0xFFE9E6DF),
    soft: Color(0xFFA8A59E),
    muted: Color(0xFF8C8A85),
    faint: Color(0xFF6E6C67),
    inverseBackground: Color(0xFFE9E6DF),
    inverseText: Color(0xFF0B0B0C),
    shareLine: Color(0xFF2A2A2D),
    logoLine: Color(0x00000000),
    whatsapp: Color(0xFF4ADE80),
    stickyShadow: BoxShadow(
        color: Color(0x80000000), offset: Offset(0, 10), blurRadius: 30),
  );
  static const light = PublicNextPalette._(
    background: Color(0xFFF4F1EA),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFE2DDD1),
    strong: Color(0xFF121212),
    text: Color(0xFF121212),
    soft: Color(0xFF4A4740),
    muted: Color(0xFF7A766C),
    faint: Color(0xFF9A958A),
    inverseBackground: Color(0xFF121212),
    inverseText: Color(0xFFF4F1EA),
    shareLine: Color(0xFFD9D4C8),
    logoLine: Color(0xFFE2DDD1),
    whatsapp: Color(0xFF1F9D55),
    stickyShadow: BoxShadow(
        color: Color(0x2E121212), offset: Offset(0, 10), blurRadius: 24),
  );

  static PublicNextPalette of(String theme) => theme == 'light' ? light : dark;

  final Color background;
  final Color surface;
  final Color line;

  /// Nom (blanc pur en sombre).
  final Color strong;
  final Color text;
  final Color soft;
  final Color muted;
  final Color faint;

  /// Bouton « inversé » : bouton fixe du bento, première ligne de l'éditorial.
  final Color inverseBackground;
  final Color inverseText;

  /// Contour du bouton rond « Partager » (éditorial).
  final Color shareLine;

  /// Contour de la tuile de logo (visible en clair seulement).
  final Color logoLine;
  final Color whatsapp;

  /// Ombre du bouton fixé en bas de l'écran.
  final BoxShadow stickyShadow;

  /// Accent en TEXTE ou en trait : ajusté pour rester lisible sur le fond
  /// et sur les surfaces (`--pc-accent-ink` côté site).
  Color accentInk(Color accent) =>
      PublicCardStyles.readableAccent(accent, [background, surface]);
}

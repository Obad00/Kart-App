import 'package:flutter/material.dart';

/// Couleurs de l'écran Carte (et des composants qui le reprennent), en
/// clair et en sombre — les widgets les lisent via
/// `Theme.of(context).extension<KartTokens>()!` (ou [KartTokens.of]) au lieu
/// de coder des couleurs en dur.
@immutable
class KartTokens extends ThemeExtension<KartTokens> {
  /// Fond de page — identique à scaffoldBackgroundColor/colorScheme.surface.
  final Color pageBackground;

  /// Titres et texte principal (bleu nuit en clair, blanc en sombre).
  final Color textPrimary;

  /// Sous-titres, libellés secondaires, icônes inactives.
  final Color textSecondary;

  /// Fond des feuilles du bas (bottom sheets) : blanc en clair, légèrement
  /// plus clair que la page en sombre pour s'en détacher (en sombre, la
  /// profondeur se lit par la luminosité, pas par l'ombre).
  final Color sheetBackground;

  /// Fond des cercles (catégories, actions rapides) et boutons secondaires.
  final Color softFill;

  /// Contour fin des cercles/boutons secondaires.
  final Color softBorder;

  /// Bleu des éléments actifs (onglet, bouton menu, icônes d'action).
  /// Éclairci en sombre pour rester lisible.
  final Color activeBlue;

  /// Fond léger derrière un élément actif bleu (bouton menu, pastilles).
  final Color activeBlueBackground;

  /// Carte de visite : noir mat, identique dans les deux thèmes.
  final Color cardBlack;

  /// Contour de la carte : transparent en clair, gris foncé en sombre pour
  /// qu'elle se détache du fond.
  final Color cardBorder;

  /// Texte et icônes sur la carte noire.
  final Color onCard;

  /// Texte secondaire sur la carte noire (titre, lignes de contact).
  final Color onCardMuted;

  /// Anneau dégradé de la catégorie active (défaut sans branding entreprise).
  final Color categoryGradientStart;
  final Color categoryGradientEnd;

  /// Libellé de la catégorie active.
  final Color categoryActiveLabel;

  /// Point "Scannez pour me contacter" et tendance à la hausse.
  final Color positive;

  /// Tendance à la baisse.
  final Color negative;

  const KartTokens({
    required this.pageBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.sheetBackground,
    required this.softFill,
    required this.softBorder,
    required this.activeBlue,
    required this.activeBlueBackground,
    required this.cardBlack,
    required this.cardBorder,
    required this.onCard,
    required this.onCardMuted,
    required this.categoryGradientStart,
    required this.categoryGradientEnd,
    required this.categoryActiveLabel,
    required this.positive,
    required this.negative,
  });

  static const light = KartTokens(
    pageBackground: Color(0xFFF5F4F0),
    textPrimary: Color(0xFF002842),
    textSecondary: Color(0xFF6B7280),
    sheetBackground: Color(0xFFFFFFFF),
    softFill: Color(0xFFEDECE8),
    softBorder: Color(0xFFE0DFDA),
    activeBlue: Color(0xFF2F6FED),
    activeBlueBackground: Color(0xFFE3ECFD),
    cardBlack: Color(0xFF111111),
    cardBorder: Color(0x00000000),
    onCard: Color(0xFFF6F6F8),
    onCardMuted: Color(0xFFB4B4BA),
    categoryGradientStart: Color(0xFFE1306C),
    categoryGradientEnd: Color(0xFFF77737),
    categoryActiveLabel: Color(0xFFE1306C),
    positive: Color(0xFF16A34A),
    negative: Color(0xFFDC2626),
  );

  static const dark = KartTokens(
    pageBackground: Color(0xFF1A1A1A),
    textPrimary: Color(0xFFF6F6F8),
    textSecondary: Color(0xFFA1A1AA),
    sheetBackground: Color(0xFF222222),
    softFill: Color(0xFF262626),
    softBorder: Color(0xFF333333),
    activeBlue: Color(0xFF7AA7FF),
    activeBlueBackground: Color(0xFF22324D),
    cardBlack: Color(0xFF111111),
    cardBorder: Color(0xFF2A2A2A),
    onCard: Color(0xFFF6F6F8),
    onCardMuted: Color(0xFFB4B4BA),
    categoryGradientStart: Color(0xFFE1306C),
    categoryGradientEnd: Color(0xFFF77737),
    categoryActiveLabel: Color(0xFFFF5C8A),
    positive: Color(0xFF4ADE80),
    negative: Color(0xFFF87171),
  );

  static KartTokens of(BuildContext context) =>
      Theme.of(context).extension<KartTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  KartTokens copyWith({
    Color? pageBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? sheetBackground,
    Color? softFill,
    Color? softBorder,
    Color? activeBlue,
    Color? activeBlueBackground,
    Color? cardBlack,
    Color? cardBorder,
    Color? onCard,
    Color? onCardMuted,
    Color? categoryGradientStart,
    Color? categoryGradientEnd,
    Color? categoryActiveLabel,
    Color? positive,
    Color? negative,
  }) {
    return KartTokens(
      pageBackground: pageBackground ?? this.pageBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      softFill: softFill ?? this.softFill,
      softBorder: softBorder ?? this.softBorder,
      activeBlue: activeBlue ?? this.activeBlue,
      activeBlueBackground: activeBlueBackground ?? this.activeBlueBackground,
      cardBlack: cardBlack ?? this.cardBlack,
      cardBorder: cardBorder ?? this.cardBorder,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      categoryGradientStart:
          categoryGradientStart ?? this.categoryGradientStart,
      categoryGradientEnd: categoryGradientEnd ?? this.categoryGradientEnd,
      categoryActiveLabel: categoryActiveLabel ?? this.categoryActiveLabel,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
    );
  }

  @override
  KartTokens lerp(ThemeExtension<KartTokens>? other, double t) {
    if (other is! KartTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return KartTokens(
      pageBackground: l(pageBackground, other.pageBackground),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      sheetBackground: l(sheetBackground, other.sheetBackground),
      softFill: l(softFill, other.softFill),
      softBorder: l(softBorder, other.softBorder),
      activeBlue: l(activeBlue, other.activeBlue),
      activeBlueBackground: l(activeBlueBackground, other.activeBlueBackground),
      cardBlack: l(cardBlack, other.cardBlack),
      cardBorder: l(cardBorder, other.cardBorder),
      onCard: l(onCard, other.onCard),
      onCardMuted: l(onCardMuted, other.onCardMuted),
      categoryGradientStart:
          l(categoryGradientStart, other.categoryGradientStart),
      categoryGradientEnd: l(categoryGradientEnd, other.categoryGradientEnd),
      categoryActiveLabel: l(categoryActiveLabel, other.categoryActiveLabel),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
    );
  }
}

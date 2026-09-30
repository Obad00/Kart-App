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

  /// Bleu des éléments actifs (icônes d'action, boutons pleins) — même bleu
  /// que les boutons de l'Explorer (#3B82F6), dans les deux thèmes.
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

  /// Fond du bouton "Afficher la carte / le QR" sous la carte.
  final Color buttonBackground;

  /// Fond du bloc QR : toujours blanc (QR noir sur blanc pour le scan).
  final Color qrBackground;

  /// Ombre douce unique de la carte.
  final Color cardShadow;

  /// Icône de la feuille "Bientôt disponible" (orange).
  final Color attention;

  /// Texte/icône posé sur un fond [activeBlue] (bouton plein).
  final Color onActiveBlue;

  /// Coin clair du dégradé métal de la carte (haut gauche).
  final Color cardSheen;

  /// Coin sombre du dégradé métal de la carte (bas droite).
  final Color cardDeep;

  /// Contour fin (1 px) des boutons sous la carte : plus léger que [softBorder], pour paraître aussi fin que celui des boutons de l'Explorer.
  final Color buttonStroke;

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
    required this.buttonBackground,
    required this.qrBackground,
    required this.cardShadow,
    required this.attention,
    required this.onActiveBlue,
    required this.cardSheen,
    required this.cardDeep,
    required this.buttonStroke,
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
    activeBlue: Color(0xFF3B82F6),
    activeBlueBackground: Color(0xFFE3ECFD),
    cardBlack: Color(0xFF111111),
    cardBorder: Color(0x00000000),
    onCard: Color(0xFFF6F6F8),
    onCardMuted: Color(0xFFB4B4BA),
    categoryGradientStart: Color(0xFFE1306C),
    categoryGradientEnd: Color(0xFFF77737),
    categoryActiveLabel: Color(0xFFE1306C),
    buttonBackground: Color(0xFFFFFFFF),
    qrBackground: Color(0xFFFFFFFF),
    cardShadow: Color(0x29000000),
    attention: Color(0xFFF59E0B),
    onActiveBlue: Color(0xFFFFFFFF),
    cardSheen: Color(0xFF1F1F1F),
    cardDeep: Color(0xFF0A0A0A),
    buttonStroke: Color(0x80D6D4CE),
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
    activeBlue: Color(0xFF3B82F6),
    activeBlueBackground: Color(0xFF22324D),
    cardBlack: Color(0xFF111111),
    cardBorder: Color(0xFF2A2A2A),
    onCard: Color(0xFFF6F6F8),
    onCardMuted: Color(0xFFB4B4BA),
    categoryGradientStart: Color(0xFFE1306C),
    categoryGradientEnd: Color(0xFFF77737),
    categoryActiveLabel: Color(0xFFFF5C8A),
    buttonBackground: Color(0xFF222222),
    qrBackground: Color(0xFFFFFFFF),
    cardShadow: Color(0x66000000),
    attention: Color(0xFFFBBF24),
    onActiveBlue: Color(0xFFFFFFFF),
    cardSheen: Color(0xFF1F1F1F),
    cardDeep: Color(0xFF0A0A0A),
    buttonStroke: Color(0x1AFFFFFF),
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
    Color? buttonBackground,
    Color? qrBackground,
    Color? cardShadow,
    Color? attention,
    Color? onActiveBlue,
    Color? cardSheen,
    Color? cardDeep,
    Color? buttonStroke,
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
      buttonBackground: buttonBackground ?? this.buttonBackground,
      qrBackground: qrBackground ?? this.qrBackground,
      cardShadow: cardShadow ?? this.cardShadow,
      attention: attention ?? this.attention,
      onActiveBlue: onActiveBlue ?? this.onActiveBlue,
      cardSheen: cardSheen ?? this.cardSheen,
      cardDeep: cardDeep ?? this.cardDeep,
      buttonStroke: buttonStroke ?? this.buttonStroke,
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
      buttonBackground: l(buttonBackground, other.buttonBackground),
      qrBackground: l(qrBackground, other.qrBackground),
      cardShadow: l(cardShadow, other.cardShadow),
      attention: l(attention, other.attention),
      onActiveBlue: l(onActiveBlue, other.onActiveBlue),
      cardSheen: l(cardSheen, other.cardSheen),
      cardDeep: l(cardDeep, other.cardDeep),
      buttonStroke: l(buttonStroke, other.buttonStroke),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
    );
  }
}

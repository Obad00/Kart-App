import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/digital_card/providers/card_provider.dart';
import 'color_contrast.dart';

/// Couleur de l'entreprise ou de l'utilisateur, en deux usages :
/// - [getCompanyColor] : texte et icônes. Rendue LISIBLE sur le fond du
///   thème en cours (contraste ≥ 4,5:1, donc aussi ≥ 3:1 pour les icônes) :
///   un accent foncé (#002842) est éclairci en thème sombre, un accent très
///   clair assombri en thème clair (accent_color_light du serveur d'abord).
/// - [getCompanyFill] : fonds pleins (boutons, pastilles) — la couleur de
///   marque exacte ; le texte posé dessus passe par readableForegroundOn.
class CompanyColorHelper {
  /// Fonds sur lesquels l'accent doit rester lisible : le plus clair des
  /// fonds sombres (cartes #222222, avec marge) et le fond de page clair.
  static const Color _darkBackground = Color(0xFF2A2A2A);
  static const Color _lightBackground = Color(0xFFF5F4F0);

  /// Couleur de texte et d'icône (avec watch).
  static Color getCompanyColor(BuildContext context) => _readable(
      context, _brand(context.watch<CardProvider>(), Theme.of(context)));

  /// Idem, sans watch.
  static Color getCompanyColorRead(BuildContext context) => _readable(
      context, _brand(context.read<CardProvider>(), Theme.of(context)));

  /// Couleur de marque exacte, pour un fond plein (avec watch).
  static Color getCompanyFill(BuildContext context) =>
      _brand(context.watch<CardProvider>(), Theme.of(context));

  /// [color] rendue lisible sur le fond du thème de [context].
  static Color readable(BuildContext context, Color color) =>
      _readable(context, color);

  static Color _readable(BuildContext context, Color color) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColorContrast.readableOn(
        color, dark ? _darkBackground : _lightBackground);
  }

  static Color _brand(CardProvider card, ThemeData theme) =>
      _parseColor(card.companyPrimaryColor) ??
      _personalAccent(card, theme.colorScheme.brightness) ??
      theme.colorScheme.primary;

  /// Couleur d'accent personnelle. En thème clair, sa variante assombrie
  /// quand le serveur en a calculé une (couleur trop pâle sur fond blanc).
  static Color? _personalAccent(CardProvider card, Brightness brightness) {
    if (brightness == Brightness.light) {
      final light = _parseColor(card.accentColorLight);
      if (light != null) return light;
    }
    return _parseColor(card.accentColor);
  }

  /// Couleur de l'entreprise, sinon null (compte individuel : l'appelant
  /// choisit alors sa propre couleur par défaut).
  static Color? getCompanyColorOrNull(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    return _parseColor(cardProvider.companyPrimaryColor);
  }

  /// Vérifie si une couleur d'entreprise est définie
  static bool hasCompanyColor(BuildContext context) {
    final cardProvider = context.read<CardProvider>();
    return cardProvider.companyPrimaryColor != null &&
        cardProvider.companyPrimaryColor!.isNotEmpty;
  }

  /// Parse une couleur hexadécimale ("#3B82F6" ou "3B82F6") ; null si
  /// absente ou invalide.
  static Color? parseHex(String? hexColor) => _parseColor(hexColor);

  /// Parse une couleur hexadécimale
  static Color? _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return null;
    try {
      String hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

/// Extension pour faciliter l'accès à la couleur de l'entreprise
extension CompanyColorContext on BuildContext {
  /// Couleur de l'entreprise ou primaire par défaut (avec watch)
  Color get companyColor => CompanyColorHelper.getCompanyColor(this);

  /// Couleur de l'entreprise ou primaire par défaut (sans watch)
  Color get companyColorRead => CompanyColorHelper.getCompanyColorRead(this);

  /// Couleur de marque exacte, pour un fond plein (avec watch)
  Color get companyFill => CompanyColorHelper.getCompanyFill(this);

  /// Vérifie si une couleur d'entreprise existe
  bool get hasCompanyColor => CompanyColorHelper.hasCompanyColor(this);
}

/// Texte noir ou blanc selon la couleur de fond, pour rester lisible quel
/// que soit l'accent choisi — sans ça, un texte "Colors.white" en dur
/// devenait illisible dès qu'une couleur d'accent claire était
/// personnalisée (ex: le bouton "Partager mon profil").
Color readableForegroundOn(Color background) {
  return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

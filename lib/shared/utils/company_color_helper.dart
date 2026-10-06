import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/digital_card/providers/card_provider.dart';

/// Helper pour obtenir la couleur de l'entreprise avec un fallback sur la couleur primaire
class CompanyColorHelper {
  /// Obtient la couleur de l'entreprise, sinon celle personnalisée par
  /// l'utilisateur, sinon la couleur primaire par défaut
  static Color getCompanyColor(BuildContext context) {
    final cardProvider = context.watch<CardProvider>();
    final colors = Theme.of(context).colorScheme;

    return _parseColor(cardProvider.companyPrimaryColor) ??
        _personalAccent(cardProvider, colors.brightness) ??
        colors.primary;
  }

  /// Idem, sans watch
  static Color getCompanyColorRead(BuildContext context) {
    final cardProvider = context.read<CardProvider>();
    final colors = Theme.of(context).colorScheme;

    return _parseColor(cardProvider.companyPrimaryColor) ??
        _personalAccent(cardProvider, colors.brightness) ??
        colors.primary;
  }

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

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
        _parseColor(cardProvider.accentColor) ??
        colors.primary;
  }

  /// Idem, sans watch
  static Color getCompanyColorRead(BuildContext context) {
    final cardProvider = context.read<CardProvider>();
    final colors = Theme.of(context).colorScheme;

    return _parseColor(cardProvider.companyPrimaryColor) ??
        _parseColor(cardProvider.accentColor) ??
        colors.primary;
  }
  
  /// Vérifie si une couleur d'entreprise est définie
  static bool hasCompanyColor(BuildContext context) {
    final cardProvider = context.read<CardProvider>();
    return cardProvider.companyPrimaryColor != null && 
           cardProvider.companyPrimaryColor!.isNotEmpty;
  }
  
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

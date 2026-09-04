import 'package:flutter/material.dart';

/// "Explorer par catégorie" — secteur avec son nombre de profils
/// correspondants. Gérable depuis le CRM web (superadmin), cf.
/// ExploreController::categories() / JobCategoryManagementController côté
/// backend. Le champ [icon] est une petite clé texte ('tech', 'finance'…)
/// traduite en IconData côté app (cf. [categoryIconFor]) — figée à un
/// ensemble fixe (choisi dans un menu côté CRM, pas de texte libre) pour
/// être sûr de toujours pouvoir dessiner une vraie icône. [color] est en
/// revanche libre, choisie par l'admin.
class ExploreCategory {
  final String name;
  final String icon;
  final Color? color;
  final int count;

  ExploreCategory({
    required this.name,
    required this.icon,
    this.color,
    required this.count,
  });

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    return ExploreCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: _parseHexColor(json['color']),
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }

  static Color? _parseHexColor(dynamic value) {
    final hex = value?.toString().replaceAll('#', '');
    if (hex == null || hex.length != 6) return null;
    final parsed = int.tryParse('FF$hex', radix: 16);
    return parsed != null ? Color(parsed) : null;
  }
}

/// Icône par clé (cf. JobCategoryManagementController::ICONS côté backend
/// — les clés doivent rester synchronisées avec cette liste). Couleur de
/// repli utilisée seulement si l'admin n'en a choisi aucune pour cette
/// catégorie.
const Map<String, ({IconData icon, Color fallbackColor})> _categoryIcons = {
  'tech': (icon: Icons.memory_rounded, fallbackColor: Color(0xFF22C55E)),
  'finance': (icon: Icons.account_balance_rounded, fallbackColor: Color(0xFF3B82F6)),
  'marketing': (icon: Icons.campaign_rounded, fallbackColor: Color(0xFFF97316)),
  'hr': (icon: Icons.groups_rounded, fallbackColor: Color(0xFF8B5CF6)),
  'design': (icon: Icons.palette_rounded, fallbackColor: Color(0xFFEC4899)),
  'education': (icon: Icons.school_rounded, fallbackColor: Color(0xFF6366F1)),
  'health': (icon: Icons.favorite_rounded, fallbackColor: Color(0xFFEF4444)),
  'law': (icon: Icons.gavel_rounded, fallbackColor: Color(0xFF0EA5E9)),
  'commerce': (icon: Icons.shopping_bag_rounded, fallbackColor: Color(0xFFF59E0B)),
  'industry': (icon: Icons.factory_rounded, fallbackColor: Color(0xFF64748B)),
};

class CategoryVisual {
  final IconData icon;
  final Color color;
  const CategoryVisual(this.icon, this.color);
}

CategoryVisual visualForCategory(ExploreCategory category) {
  final entry = _categoryIcons[category.icon];
  return CategoryVisual(
    entry?.icon ?? Icons.category_rounded,
    category.color ?? entry?.fallbackColor ?? const Color(0xFF64748B),
  );
}

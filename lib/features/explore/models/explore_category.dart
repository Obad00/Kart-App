import 'package:flutter/material.dart';

/// "Explorer par catégorie" — secteur avec son nombre de profils
/// correspondants (cf. ExploreController::categories() / JobSectors côté
/// backend). Le champ [icon] est une petite clé texte ('tech', 'finance'…)
/// traduite en IconData/couleur côté app (cf. _categoryVisuals).
class ExploreCategory {
  final String name;
  final String icon;
  final int count;

  ExploreCategory({required this.name, required this.icon, required this.count});

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    return ExploreCategory(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
    );
  }
}

class CategoryVisual {
  final IconData icon;
  final Color color;
  const CategoryVisual(this.icon, this.color);
}

/// Icône + couleur par clé de secteur (cf. JobSectors::all() côté backend
/// — les clés doivent rester synchronisées avec ce fichier).
const Map<String, CategoryVisual> categoryVisuals = {
  'tech': CategoryVisual(Icons.memory_rounded, Color(0xFF22C55E)),
  'finance': CategoryVisual(Icons.account_balance_rounded, Color(0xFF3B82F6)),
  'marketing': CategoryVisual(Icons.campaign_rounded, Color(0xFFF97316)),
  'hr': CategoryVisual(Icons.groups_rounded, Color(0xFF8B5CF6)),
  'design': CategoryVisual(Icons.palette_rounded, Color(0xFFEC4899)),
  'education': CategoryVisual(Icons.school_rounded, Color(0xFF6366F1)),
  'health': CategoryVisual(Icons.favorite_rounded, Color(0xFFEF4444)),
  'law': CategoryVisual(Icons.gavel_rounded, Color(0xFF0EA5E9)),
  'commerce': CategoryVisual(Icons.shopping_bag_rounded, Color(0xFFF59E0B)),
  'industry': CategoryVisual(Icons.factory_rounded, Color(0xFF64748B)),
};

CategoryVisual visualForCategory(String icon) =>
    categoryVisuals[icon] ??
    const CategoryVisual(Icons.category_rounded, Color(0xFF64748B));

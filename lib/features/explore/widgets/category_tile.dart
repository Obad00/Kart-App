import 'package:flutter/material.dart';
import '../models/explore_category.dart';

/// Une case du grid "Explorer par catégorie" — icône colorée, nom du
/// secteur, nombre de profils. cf. maquette fournie.
class CategoryTile extends StatelessWidget {
  final ExploreCategory category;
  final VoidCallback onTap;

  const CategoryTile({super.key, required this.category, required this.onTap});

  String _countLabel(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      final formatted =
          k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '$formatted K profils';
    }
    return '$count profil${count > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visual = visualForCategory(category);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(visual.icon, color: visual.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _countLabel(category.count),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

const exploreThemeBlue = Color(0xFF3B82F6);

/// En-tête partagé par tous les carrousels de la page Explorer (refonte) —
/// titre, sous-titre, "Voir tout" optionnel. cf. maquette fournie.
class ExploreSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;

  const ExploreSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    // 17 tronquait les titres les plus longs ("Les profils
                    // qui font votre secteur"...) sur les petits écrans,
                    // surtout à côté de "Voir tout". Réduit + autorisé sur
                    // 2 lignes plutôt qu'ellipsé sur 1 seule.
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onSeeAll != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSeeAll,
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: exploreThemeBlue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

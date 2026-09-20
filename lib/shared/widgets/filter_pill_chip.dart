import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Puce de filtre/onglet cliquable (Explorer, Mes demandes, Contacts...).
///
/// Remonté côté produit : chaque page réimplémentait sa propre version
/// (parfois un `ChoiceChip` Material, parfois un `Material`+`InkWell` fait
/// main), avec des divergences visuelles subtiles mais visibles — surtout
/// en mode clair — dues aux effets par défaut de `ChoiceChip` (tinte de
/// surface et légère élévation propres à Material 3) qu'un `Material` brut
/// avec `elevation: 0` n'a pas. Un seul widget partagé élimine ce risque de
/// divergence pour de bon, plutôt que de rattraper les mêmes couleurs/
/// contours à la main à chaque nouvelle page.
class FilterPillChip extends StatelessWidget {
  const FilterPillChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  static const _themeBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: active ? _themeBlue : colors.onSurface.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _themeBlue.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : colors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/company_color_helper.dart';

/// Loader plein écran homogène — même habillage que celui de "Mes
/// contacts" (spinner à la couleur de l'entreprise + libellé en dessous),
/// remonté côté produit comme la référence à reproduire partout plutôt que
/// chaque écran avec son propre CircularProgressIndicator nu.
class AppLoader extends StatelessWidget {
  final String label;

  const AppLoader({super.key, this.label = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // context.companyColor retombe déjà sur colors.primary si le compte
    // n'a pas d'entreprise (cf. CompanyColorHelper) — même repli que
    // partout ailleurs dans l'app.
    final brand = context.companyColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(brand),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

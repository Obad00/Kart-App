import 'package:flutter/material.dart';

/// Fiche détaillée d'une offre (titre, entreprise, lieu, description) —
/// partagée entre le fil de suggestions (job_swipe_card.dart) et le
/// tableau de bord (Matchs/Aimées), pour qu'un candidat puisse consulter
/// le détail d'une offre à laquelle il a déjà matché ou likée, pas
/// seulement pendant qu'elle défile dans le fil.
void showJobDetailsSheet(
  BuildContext context, {
  required String title,
  required String companyName,
  String? location,
  String? description,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colors = Theme.of(sheetContext).colorScheme;
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [companyName, location]
                      .where((v) => (v ?? '').isNotEmpty)
                      .join(' · '),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      (description == null || description.isEmpty)
                          ? 'Aucune description fournie pour cette offre.'
                          : description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colors.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

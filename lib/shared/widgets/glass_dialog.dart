import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'glass_sheet.dart';

/// Popup en verre dépoli — remplace les AlertDialog/Dialog à fond plat
/// disséminés dans l'app (suppression, déconnexion, erreurs...), pour la
/// même cohérence visuelle que GlassAppBar/la pilule de nav/GlassSheet
/// (remonté côté produit : "je veux que les popups soient homogènes,
/// utilise l'effet de glassmorphisme comme le HomeShell"). Même pattern
/// déjà utilisé ponctuellement dans home_shell.dart (rappel de mise à
/// jour, rappel de complétion de profil) — généralisé ici.
class GlassDialog extends StatelessWidget {
  final Widget child;

  const GlassDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassSheet(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  /// Boîte de confirmation générique (titre + message + Annuler/Confirmer)
  /// — couvre la majorité des popups de confirmation de l'app (suppression,
  /// déconnexion...). Retourne true si l'action a été confirmée, false
  /// sinon (annulé ou fermé sans choisir).
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Annuler',
    String confirmLabel = 'Confirmer',
    bool isDestructive = true,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final dialogColors = Theme.of(dialogContext).colorScheme;
        return GlassDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dialogColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: dialogColors.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        color: dialogColors.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        color: isDestructive ? Colors.redAccent : dialogColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Popup purement informative (titre + message + un seul bouton) — pour
  /// les AlertDialog d'erreur/validation à bouton unique disséminés dans
  /// l'app (au lieu de confirm(), pensé pour un choix Annuler/Confirmer).
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dialogColors = Theme.of(dialogContext).colorScheme;
        return GlassDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dialogColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: dialogColors.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      color: dialogColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

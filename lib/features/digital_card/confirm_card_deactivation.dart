import 'package:flutter/material.dart';

import '../../core/theme/kart_tokens.dart';
import '../../shared/widgets/glass_dialog.dart';

/// Confirmation avant de désactiver la carte (is_public = false) : son lien,
/// son QR code et sa carte NFC cessent alors de fonctionner. Même fenêtre
/// verre que « Désactiver la carte NFC ». Renvoie true si l'utilisateur
/// confirme.
Future<bool> confirmCardDeactivation(BuildContext context) async {
  final t = KartTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return GlassDialog(
        key: const Key('card-deactivation-dialog'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre lien, votre QR code et votre carte NFC ne fonctionneront plus. Continuer ?',
              style:
                  TextStyle(fontSize: 15, height: 1.4, color: colors.onSurface),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  key: const Key('card-deactivation-confirm'),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: TextButton.styleFrom(foregroundColor: t.negative),
                  child: const Text('Continuer',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return confirmed == true;
}

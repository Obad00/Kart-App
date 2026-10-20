import 'package:flutter/material.dart';

import '../../core/theme/kart_tokens.dart';

/// Confirmation avant de désactiver la carte (is_public = false) : son lien,
/// son QR code et sa carte NFC cessent alors de fonctionner. Même boîte que
/// « Désactiver la carte NFC ». Renvoie true si l'utilisateur confirme.
Future<bool> confirmCardDeactivation(BuildContext context) async {
  final t = KartTokens.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('card-deactivation-dialog'),
      content: const Text(
        'Votre lien, votre QR code et votre carte NFC ne fonctionneront plus. Continuer ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          key: const Key('card-deactivation-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: t.negative),
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

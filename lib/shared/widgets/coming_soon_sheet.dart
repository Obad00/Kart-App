import 'package:flutter/material.dart';

import '../../core/theme/kart_tokens.dart';

/// Feuille "Fonctionnalité bientôt disponible" — même présentation que celle
/// du scan de cartes physiques (ScanPage), mais aux couleurs du thème et
/// avec un texte propre à chaque fonctionnalité.
class ComingSoonSheet extends StatelessWidget {
  final String message;

  const ComingSoonSheet({super.key, required this.message});

  static Future<void> show(BuildContext context, {required String message}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ComingSoonSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: t.attention),
            const SizedBox(height: 16),
            Text(
              'Fonctionnalité bientôt disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Bleu actif du thème plutôt que le bouton sombre par défaut
                // du thème sombre, peu visible sur le fond de la feuille.
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.activeBlue,
                  foregroundColor: t.onActiveBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Compris',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NoCardCta extends StatelessWidget {
  final VoidCallback onCreate;

  const NoCardCta({super.key, required this.onCreate});

  static const _accent = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_accent, Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.qr_code_2, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Text(
          'Aucune carte créée',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Créez votre carte de visite digitale pour commencer à la partager.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Créer ma carte'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            // fontFamily explicite : sans lui, ce textStyle remplace le
            // DefaultTextStyle ambiant du thème (Syne) par la police système
            // par défaut — cf. même correctif sur ProfilePage.
            textStyle: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            shadowColor: _accent.withValues(alpha: 0.4),
          ).copyWith(
            elevation: WidgetStateProperty.all(6),
          ),
        ),
      ],
    );
  }
}

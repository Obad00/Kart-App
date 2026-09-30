import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import '../providers/card_provider.dart';

/// Bloc statistiques sous les actions rapides : scans et nouveaux contacts
/// des 7 derniers jours, avec une petite flèche de tendance par rapport aux
/// 7 jours précédents. Les chiffres viennent uniquement de l'API
/// (GET /me/card-stats) — l'écran ne l'affiche pas sans données.
class CardStatsRow extends StatelessWidget {
  final CardWeeklyStats stats;

  const CardStatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: t.softBorder),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.qr_code_scanner_rounded,
                  value: stats.scansThisWeek,
                  previous: stats.scansPreviousWeek,
                  label: stats.scansThisWeek > 1
                      ? 'scans cette semaine'
                      : 'scan cette semaine',
                ),
              ),
              VerticalDivider(width: 24, thickness: 1, color: t.softBorder),
              Expanded(
                child: _StatTile(
                  icon: Icons.person_outline_rounded,
                  value: stats.newContactsThisWeek,
                  previous: stats.newContactsPreviousWeek,
                  label: stats.newContactsThisWeek > 1
                      ? 'nouveaux contacts'
                      : 'nouveau contact',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final int previous;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.previous,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    // Pas de flèche sans point de comparaison (semaine précédente vide,
    // ex: juste après la mise en place du suivi) ni à égalité.
    final IconData? trendIcon = previous == 0 || value == previous
        ? null
        : (value > previous
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);
    final Color trendColor = value > previous ? t.positive : t.negative;

    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: t.softFill,
              shape: BoxShape.circle,
              border: Border.all(color: t.softBorder),
            ),
            child: Icon(icon, size: 22, color: t.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    if (trendIcon != null) ...[
                      const SizedBox(width: 6),
                      Icon(trendIcon, size: 18, color: trendColor),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.textSecondary,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

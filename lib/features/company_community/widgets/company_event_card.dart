import 'package:flutter/material.dart';

import '../models/company_event_summary.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Carte d'un événement de l'entreprise dans "Ma communauté" — même esprit
/// visuel que CompanyDiscoverCard/CommunityCard (carte blanche/surface,
/// coins arrondis, ombre légère) pour rester cohérent avec le reste
/// d'Explorer plutôt que d'introduire un nouveau style.
class CompanyEventCard extends StatelessWidget {
  final CompanyEventSummary event;
  final VoidCallback onTap;

  const CompanyEventCard({super.key, required this.event, required this.onTap});

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ended = event.hasEnded;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 178,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (ended ? Colors.grey : _themeBlue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ended ? 'Terminé' : 'Actif',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ended ? Colors.grey.shade600 : _themeBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (event.startsAt != null)
                    Text(
                      _formatDate(event.startsAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                event.name,
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.location?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  event.location!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.people_alt_rounded,
                      size: 14, color: colors.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${event.participantsCount} inscrit${event.participantsCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

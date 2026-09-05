import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/utils/relative_time.dart';
import '../jobmatch_theme.dart';

/// Détail complet d'une offre — page dédiée (pas une simple feuille), cf.
/// maquette fournie : en-tête entreprise, titre, salaire, compétences,
/// description, et l'action "Je suis intéressé" quand elle a un sens
/// (fil de suggestions) — masquée pour un historique en lecture seule
/// (Matchs/Sauvegardées/Passées du tableau de bord).
class JobDetailPage extends StatelessWidget {
  final String title;
  final String companyName;
  final String? companyLogo;
  final String? location;
  final bool isRemote;
  final String? contractType;
  final int? salaryMin;
  final int? salaryMax;
  final int? experienceRequired;
  final String? description;
  final DateTime? publishedAt;
  final List<String> skills;
  final int? score;
  final VoidCallback? onInterested;

  const JobDetailPage({
    super.key,
    required this.title,
    required this.companyName,
    this.companyLogo,
    this.location,
    this.isRemote = false,
    this.contractType,
    this.salaryMin,
    this.salaryMax,
    this.experienceRequired,
    this.description,
    this.publishedAt,
    this.skills = const [],
    this.score,
    this.onInterested,
  });

  String? get _logoUrl {
    final logo = companyLogo;
    if (logo == null || logo.isEmpty) return null;
    return logo.startsWith('http') ? logo : '${ApiEndpoints.storageUrl}/$logo';
  }

  String? get _salaryLabel {
    if (salaryMin == null && salaryMax == null) return null;
    if (salaryMin != null && salaryMax != null) {
      return '$salaryMin - $salaryMax FCFA / mois';
    }
    return '${salaryMin ?? salaryMax} FCFA / mois';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final metaParts = [
      if (isRemote) 'À distance' else location,
      contractType,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colors.onSurface,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: jobMatchAccent.withValues(alpha: 0.1),
                            child: _logoUrl != null
                                ? Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: CachedNetworkImage(
                                      imageUrl: _logoUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) =>
                                          _logoFallback(),
                                    ),
                                  )
                                : _logoFallback(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      companyName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: colors.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded,
                                      size: 15, color: jobMatchAccent),
                                ],
                              ),
                              if (metaParts.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  metaParts,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (publishedAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Publiée ${relativeTimeLabel(publishedAt!)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color:
                                        colors.onSurface.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    if (score != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 15,
                              color: jobMatchAccent.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            '$score% de correspondance avec votre profil',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: jobMatchAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_salaryLabel != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _salaryLabel!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: jobMatchLike,
                        ),
                      ),
                    ],
                    if (skills.isNotEmpty || experienceRequired != null) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...skills.map((s) => _buildChip(colors, s)),
                          if (experienceRequired != null)
                            _buildChip(colors,
                                "$experienceRequired an${experienceRequired! > 1 ? 's' : ''} d'expérience"),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      'À propos du poste',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (description == null || description!.isEmpty)
                          ? 'Aucune description fournie pour cette offre.'
                          : description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: colors.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (onInterested != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onInterested!();
                      Navigator.pop(context);
                    },
                    icon:
                        const Icon(Icons.favorite_rounded, color: Colors.white),
                    label: const Text('Je suis intéressé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jobMatchLike,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _logoFallback() {
    return Center(
      child: Text(
        companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: jobMatchAccent,
        ),
      ),
    );
  }

  Widget _buildChip(ColorScheme colors, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

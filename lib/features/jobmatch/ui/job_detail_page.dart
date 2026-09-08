import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/utils/relative_time.dart';
import '../jobmatch_theme.dart';
import '../model/contract_type_label.dart';

/// Détail complet d'une offre — feuille modale (DraggableScrollableSheet),
/// même présentation que "Voir tout" pour Expériences/Formation sur la
/// carte publique, pour que l'affichage d'un détail soit homogène dans
/// toute l'app plutôt qu'une page dédiée à part. En-tête entreprise,
/// titre, salaire, compétences, description, et l'action "Je suis
/// intéressé" quand elle a un sens (fil de suggestions) — masquée pour un
/// historique en lecture seule (Matchs/Sauvegardées/Passées du tableau de
/// bord).
void showJobDetailSheet(
  BuildContext context, {
  required String title,
  required String companyName,
  String? companyLogo,
  String? location,
  bool isRemote = false,
  String? contractType,
  int? salaryMin,
  int? salaryMax,
  int? experienceRequired,
  String? description,
  DateTime? publishedAt,
  List<String> skills = const [],
  int? score,
  VoidCallback? onInterested,
  VoidCallback? onPass,
  VoidCallback? onSave,
  bool isSaved = false,
}) {
  final colors = Theme.of(context).colorScheme;

  showModalBottomSheet(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => _JobDetailSheetContent(
        title: title,
        companyName: companyName,
        companyLogo: companyLogo,
        location: location,
        isRemote: isRemote,
        contractType: contractType,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        experienceRequired: experienceRequired,
        description: description,
        publishedAt: publishedAt,
        skills: skills,
        score: score,
        onInterested: onInterested,
        onPass: onPass,
        onSave: onSave,
        isSaved: isSaved,
        scrollController: scrollController,
      ),
    ),
  );
}

class _JobDetailSheetContent extends StatelessWidget {
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
  final VoidCallback? onPass;
  final VoidCallback? onSave;
  final bool isSaved;
  final ScrollController scrollController;

  const _JobDetailSheetContent({
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
    this.onPass,
    this.onSave,
    this.isSaved = false,
    required this.scrollController,
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
      contractType != null ? contractTypeLabel(contractType!) : null,
    ].where((e) => e != null && e.isNotEmpty).join(' · ');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                                color: colors.onSurface.withValues(alpha: 0.55),
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
                                color: colors.onSurface.withValues(alpha: 0.4),
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
                    fontSize: 22,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
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
                const SizedBox(height: 24),
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
              ],
            ),
          ),
        ),
        if (onInterested != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            // Mêmes actions que sur la carte (Passer/Sauvegarder/Intéressé)
            // — ouvrir le détail ne doit pas priver l'utilisateur de ces
            // gestes, sinon il faut fermer la fiche pour agir sur l'offre.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onPass != null)
                  _buildRoundAction(
                    colors: colors,
                    icon: Icons.close_rounded,
                    label: 'Passer',
                    color: Colors.red,
                    onTap: () {
                      onPass!();
                      Navigator.pop(context);
                    },
                  ),
                if (onSave != null)
                  _buildRoundAction(
                    colors: colors,
                    icon: isSaved
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    label: 'Sauvegarder',
                    color: Colors.amber.shade700,
                    small: true,
                    onTap: () {
                      onSave!();
                      Navigator.pop(context);
                    },
                  ),
                _buildRoundAction(
                  colors: colors,
                  icon: Icons.favorite_rounded,
                  label: 'Intéressé',
                  color: jobMatchLike,
                  onTap: () {
                    onInterested!();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Même présentation que les boutons ronds du fil de suggestions
  // (JobMatchFeedPage._buildActionButton) pour rester cohérent visuellement.
  Widget _buildRoundAction({
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool small = false,
  }) {
    final size = small ? 46.0 : 58.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border:
                  Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: small ? 20 : 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
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

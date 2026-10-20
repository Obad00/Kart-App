import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../auth/models/profile_score.dart';
import '../../auth/providers/auth_provider.dart';
import '../helpers/completion_helper.dart';
import '../profile_item_opener.dart';
import '../providers/profile_completion_provider.dart';
import '../providers/candidate_skills_provider.dart';
import '../ui/completion_form_page.dart';
import 'package:provider/provider.dart';

/// Carte « Complétez votre profil » (Profil) : le score du serveur
/// (ProfileScoreService, la même source que l'admin et l'Explorer) et
/// l'élément manquant suivant ; un toucher ouvre directement l'écran qui le
/// complète. Avec un serveur qui ne renvoie pas encore le score, l'ancien
/// calcul local sert de repli.
class CompletionBanner extends StatelessWidget {
  const CompletionBanner({super.key, this.onOpen = openProfileItem});

  /// Ouvre l'écran d'un critère (remplaçable dans les tests).
  final Future<void> Function(BuildContext context, String key) onOpen;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileCompletionProvider>();
    final skillsProvider = context.watch<CandidateSkillsProvider>();
    final serverScore = context.watch<AuthProvider>().user?.profileScore;
    final model = provider.model;
    final colors = Theme.of(context).colorScheme;

    final double percent;
    final List<String> missing;
    final ProfileCriterion? next;
    if (serverScore != null) {
      percent = serverScore.score.toDouble();
      next = serverScore.next;
      missing = serverScore.criteria.where((c) => !c.done && c.key != next?.key).map((c) => c.label).toList();
    } else {
      final result = CompletionHelper.calculate(model, hasSkills: skillsProvider.skills.isNotEmpty);
      percent = result.percent;
      next = null;
      missing = result.missing;
    }

    // Profil complet : afficher la carte récapitulative
    if (percent >= 100) {
      return _buildCompletedCard(
        context,
        colors,
        model,
        skillsProvider.skills.length,
      );
    }

    // Profil incomplet : afficher le banner d'invitation
    return _buildIncompleteBanner(context, colors, percent: percent, missing: missing, next: next);
  }

  Widget _buildIncompleteBanner(BuildContext context, ColorScheme colors,
      {required double percent, required List<String> missing, ProfileCriterion? next}) {
    final progress = percent / 100;
    const accentColor = Color(0xFFF59E0B);

    return GestureDetector(
      key: const Key('completion-banner'),
      onTap: () {
        HapticFeedback.lightImpact();
        // L'élément suivant s'il est connu, sinon tout le formulaire.
        onOpen(context, next?.key ?? '');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complétez votre profil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percent.toInt()}% complété',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.onSurface.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 12),
              Row(
                key: const Key('completion-next'),
                children: [
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ensuite : ${next.label}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                  ),
                  Text(
                    '+${next.weight} %',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                  ),
                ],
              ),
            ],
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: missing
                    .take(3)
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colors.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, ColorScheme colors,
      dynamic model, int skillsCount) {
    const blueColor = Color(0xFF3B82F6);

    // Collecter les réseaux sociaux disponibles
    final socials = <_SocialItem>[];
    if (_hasValue(model.linkedin)) {
      socials.add(_SocialItem(
          'LinkedIn', FontAwesomeIcons.linkedin, const Color(0xFF0A66C2)));
    }
    if (_hasValue(model.instagram)) {
      socials.add(_SocialItem(
          'Instagram', FontAwesomeIcons.instagram, const Color(0xFFE4405F)));
    }
    if (_hasValue(model.tiktok)) {
      socials.add(_SocialItem(
          'TikTok', FontAwesomeIcons.tiktok, const Color(0xFF111111)));
    }
    if (_hasValue(model.github)) {
      socials.add(_SocialItem(
          'GitHub', FontAwesomeIcons.github, const Color(0xFF333333)));
    }
    if (_hasValue(model.facebook)) {
      socials.add(_SocialItem(
          'Facebook', FontAwesomeIcons.facebook, const Color(0xFF1877F2)));
    }
    if (_hasValue(model.website)) {
      socials.add(_SocialItem(
          'Site web', FontAwesomeIcons.globe, const Color(0xFF6366F1)));
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.onSurface.withValues(alpha: 0.02),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mon profil',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const CompletionFormPage(),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: blueColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: blueColor.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: blueColor),
                        SizedBox(width: 4),
                        Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: blueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Infos principales
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (_hasValue(model.phone))
                  _buildInfoLine(colors, Icons.phone_outlined, model.phone!),
                if (_hasValue(model.email))
                  _buildInfoLine(colors, Icons.email_outlined, model.email!),
              ],
            ),
          ),

          // Réseaux sociaux
          if (socials.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: socials
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: s.color.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              s.icon is IconData
                                  ? Icon(s.icon, size: 14, color: s.color)
                                  : FaIcon(s.icon, size: 14, color: s.color),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: s.color,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],

          // Expériences, Formations & Compétences résumé
          if (model.experiences.isNotEmpty ||
              model.educations.isNotEmpty ||
              skillsCount > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (model.experiences.isNotEmpty)
                    _buildBadge(
                      colors,
                      Icons.work_outline,
                      '${model.experiences.length} exp.',
                      blueColor,
                    ),
                  if (model.educations.isNotEmpty)
                    _buildBadge(
                      colors,
                      Icons.school_outlined,
                      '${model.educations.length} formation${model.educations.length > 1 ? 's' : ''}',
                      const Color(0xFF8B5CF6),
                    ),
                  if (skillsCount > 0)
                    _buildBadge(
                      colors,
                      Icons.psychology_outlined,
                      '$skillsCount compétence${skillsCount > 1 ? 's' : ''}',
                      Colors.green,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildInfoLine(ColorScheme colors, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
      ColorScheme colors, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class _SocialItem {
  final String label;
  final dynamic icon;
  final Color color;
  const _SocialItem(this.label, this.icon, this.color);
}

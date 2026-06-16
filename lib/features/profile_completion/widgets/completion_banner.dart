import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import '../helpers/completion_helper.dart';
import '../providers/profile_completion_provider.dart';
import '../ui/completion_checklist_page.dart';
import '../ui/completion_form_page.dart';
import 'package:provider/provider.dart';

class CompletionBanner extends StatelessWidget {
  const CompletionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileCompletionProvider>();
    final model = provider.model;
    final result = CompletionHelper.calculate(model);
    final colors = Theme.of(context).colorScheme;

    // Profil complet : afficher la carte récapitulative
    if (result.percent >= 100) {
      return _buildCompletedCard(context, colors, model);
    }

    // Profil incomplet : afficher le banner d'invitation
    return _buildIncompleteBanner(context, colors, result);
  }

  Widget _buildIncompleteBanner(
      BuildContext context, ColorScheme colors, CompletionResult result) {
    final progress = result.percent / 100;
    const accentColor = Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CompletionChecklistPage(),
          ),
        );
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
                        '${result.percent.toInt()}% complété',
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
            if (result.missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result.missing.take(3).map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(
      BuildContext context, ColorScheme colors, dynamic model) {
    const blueColor = Color(0xFF3B82F6);

    // Collecter les réseaux sociaux disponibles
    final socials = <_SocialItem>[];
    if (_hasValue(model.linkedin)) {
      socials.add(_SocialItem('LinkedIn', FontAwesome.linkedin_brand, const Color(0xFF0A66C2)));
    }
    if (_hasValue(model.instagram)) {
      socials.add(_SocialItem('Instagram', FontAwesome.instagram_brand, const Color(0xFFE4405F)));
    }
    if (_hasValue(model.github)) {
      socials.add(_SocialItem('GitHub', FontAwesome.github_brand, const Color(0xFF333333)));
    }
    if (_hasValue(model.facebook)) {
      socials.add(_SocialItem('Facebook', FontAwesome.facebook_brand, const Color(0xFF1877F2)));
    }
    if (_hasValue(model.website)) {
      socials.add(_SocialItem('Site web', FontAwesome.globe_solid, const Color(0xFF6366F1)));
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CompletionChecklistPage(),
          ),
        );
      },
      child: Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: blueColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: blueColor.withValues(alpha: 0.2)),
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
                  children: socials.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: s.color.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 14, color: s.color),
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
                  )).toList(),
                ),
              ),
            ],

            // Expériences & Formations résumé
            if (model.experiences.isNotEmpty || model.educations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (model.experiences.isNotEmpty)
                      _buildBadge(
                        colors,
                        Icons.work_outline,
                        '${model.experiences.length} exp.',
                        blueColor,
                      ),
                    if (model.experiences.isNotEmpty && model.educations.isNotEmpty)
                      const SizedBox(width: 8),
                    if (model.educations.isNotEmpty)
                      _buildBadge(
                        colors,
                        Icons.school_outlined,
                        '${model.educations.length} formation${model.educations.length > 1 ? 's' : ''}',
                        const Color(0xFF8B5CF6),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ),
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

  Widget _buildBadge(ColorScheme colors, IconData icon, String label, Color color) {
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
  final IconData icon;
  final Color color;
  const _SocialItem(this.label, this.icon, this.color);
}

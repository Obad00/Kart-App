import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../model/skill_model.dart';
import '../providers/profile_completion_provider.dart';
import '../providers/candidate_skills_provider.dart';
import '../ui/completion_form_page.dart';
import '../ui/skill_editor_sheet.dart';

/// Réseaux sociaux, Expériences, Formation et Compétences — embarqué
/// directement dans l'onglet Profil. "Informations de base" (Poste,
/// Entreprise, Téléphone, Email) n'est volontairement pas ici : elle est
/// fusionnée avec "Informations personnelles" dans ProfilePage pour éviter
/// la répétition de l'email entre les deux écrans.
///
/// Chaque section est repliable (chevron) — sinon la page devient très
/// longue à scroller dès qu'on ajoute plusieurs expériences/formations.
class CompletionSections extends StatefulWidget {
  const CompletionSections({super.key});

  @override
  State<CompletionSections> createState() => _CompletionSectionsState();
}

class _CompletionSectionsState extends State<CompletionSections> {
  bool _socialExpanded = false;
  bool _experiencesExpanded = false;
  bool _educationsExpanded = false;
  bool _skillsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfileCompletionProvider>().model;
    final skills = context.watch<CandidateSkillsProvider>().skills;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          context,
          colors: colors,
          icon: Icons.share_outlined,
          title: 'Réseaux sociaux',
          onAddTap: () => _openForm(context, section: 'social'),
          expanded: _socialExpanded,
          onToggle: () => setState(() => _socialExpanded = !_socialExpanded),
          items: [
            _CheckItem('LinkedIn', model.linkedin, Icons.work_outline),
            _CheckItem('Instagram', model.instagram, Icons.camera_alt_outlined),
            _CheckItem('GitHub', model.github, Icons.code),
            _CheckItem('Facebook', model.facebook, Icons.facebook),
            _CheckItem('Site web', model.website, Icons.language),
          ],
        ),
        const SizedBox(height: 16),

        _buildExperiencesSection(context, colors, model),
        const SizedBox(height: 16),

        _buildEducationsSection(context, colors, model),
        const SizedBox(height: 16),

        _buildSkillsSection(context, colors, skills),
      ],
    );
  }

  void _openForm(BuildContext context, {String? section}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompletionFormPage(section: section),
    );
  }

  Widget _buildSectionHeader(
    ColorScheme colors, {
    required IconData icon,
    required String title,
    required VoidCallback onAddTap,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
              ),
            ),
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required ColorScheme colors,
    required IconData icon,
    required String title,
    required List<_CheckItem> items,
    required VoidCallback onAddTap,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            icon: icon,
            title: title,
            onAddTap: onAddTap,
            expanded: expanded,
            onToggle: onToggle,
          ),
          if (expanded) ...[
            ...items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final hasValue = item.value != null && item.value!.trim().isNotEmpty;
              return Column(
                children: [
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.05)),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 18, color: colors.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasValue ? item.value! : 'Non renseigné',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasValue ? colors.onSurface : colors.onSurface.withValues(alpha: 0.3),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: hasValue
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasValue ? Icons.check_rounded : Icons.add_rounded,
                            size: 16,
                            color: hasValue ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildExperiencesSection(BuildContext context, ColorScheme colors, dynamic model) {
    final experiences = model.experiences as List;

    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            icon: Icons.history,
            title: 'Expériences',
            onAddTap: () => _openForm(context, section: 'experiences'),
            expanded: _experiencesExpanded,
            onToggle: () => setState(() => _experiencesExpanded = !_experiencesExpanded),
          ),
          if (_experiencesExpanded) ...[
            if (experiences.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'Aucune expérience ajoutée',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...experiences.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                final title = exp.title ?? '';
                final company = exp.company ?? '';
                final startDate = exp.startDate ?? '';
                final endDate = exp.endDate;
                final description = exp.description ?? '';

                return Column(
                  children: [
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.05)),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.work_outline, size: 18, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  company,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? '$startDate → $endDate'
                                      : '$startDate → Présent',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurface.withValues(alpha: 0.45),
                                  ),
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurface.withValues(alpha: 0.55),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, size: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationsSection(BuildContext context, ColorScheme colors, dynamic model) {
    final educations = model.educations as List;

    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            icon: Icons.school_outlined,
            title: 'Formation',
            onAddTap: () => _openForm(context, section: 'educations'),
            expanded: _educationsExpanded,
            onToggle: () => setState(() => _educationsExpanded = !_educationsExpanded),
          ),
          if (_educationsExpanded) ...[
            if (educations.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 18, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'Aucune formation ajoutée',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...educations.asMap().entries.map((entry) {
                final i = entry.key;
                final edu = entry.value;
                final degree = edu.degree ?? '';
                final school = edu.school ?? '';
                final field = edu.field ?? '';
                final startYear = edu.startYear?.toString() ?? '';
                final endYear = edu.endYear?.toString() ?? '';

                return Column(
                  children: [
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.05)),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  degree,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  school,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (field.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          field,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF8B5CF6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    if (field.isNotEmpty) const SizedBox(width: 8),
                                    Text(
                                      '$startYear - $endYear',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.onSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, size: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection(
    BuildContext context,
    ColorScheme colors,
    List<CandidateSkillModel> skills,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            colors,
            icon: Icons.psychology_outlined,
            title: 'Compétences',
            onAddTap: () => _openSkillEditor(context),
            expanded: _skillsExpanded,
            onToggle: () => setState(() => _skillsExpanded = !_skillsExpanded),
          ),
          if (_skillsExpanded) ...[
            if (skills.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined, size: 18, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      'Aucune compétence ajoutée',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) => SkillChip(label: s.name, subtitle: levelLabel(s.level)))
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _openSkillEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SkillEditorSheet(),
    );
  }
}

class _CheckItem {
  final String label;
  final String? value;
  final IconData icon;
  const _CheckItem(this.label, this.value, this.icon);
}

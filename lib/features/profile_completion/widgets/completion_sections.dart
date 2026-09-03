import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../model/skill_model.dart';
import '../providers/profile_completion_provider.dart';
import '../providers/candidate_skills_provider.dart';
import '../ui/completion_form_page.dart';
import '../ui/skill_editor_sheet.dart';
import '../ui/interests_editor_sheet.dart';

// Rose partout dans "Centres d'intérêt" — bouton "+", puces de l'éditeur ET
// puces en lecture seule — même structure de puce (SkillChip) que
// "Compétences", mais couleur propre pour se différencier visuellement.
const _interestsAccentColor = Color(0xFFEC4899);

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
  bool _educationsExpanded = false;
  bool _skillsExpanded = false;
  bool _interestsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfileCompletionProvider>().model;
    final skills = context.watch<CandidateSkillsProvider>().skills;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExperiencesSection(context, colors, model),
        const SizedBox(height: 16),
        _buildEducationsSection(context, colors, model),
        const SizedBox(height: 16),
        _buildSkillsSection(context, colors, skills),
        const SizedBox(height: 16),
        // Après Compétences plutôt qu'en premier — ordre demandé.
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
        _buildInterestsSection(context, colors, model.interests),
      ],
    );
  }

  void _openForm(BuildContext context,
      {String? section, bool addOnly = false, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompletionFormPage(
        section: section,
        addOnly: addOnly,
        editIndex: editIndex,
      ),
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
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface),
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
                child: const Icon(Icons.add_rounded,
                    size: 18, color: Color(0xFF3B82F6)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
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
              final hasValue =
                  item.value != null && item.value!.trim().isNotEmpty;
              return Column(
                children: [
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                          height: 1,
                          color: colors.onSurface.withValues(alpha: 0.05)),
                    ),
                  InkWell(
                    onTap: onAddTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              size: 18,
                              color: colors.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        colors.onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasValue ? item.value! : 'Non renseigné',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: hasValue
                                        ? colors.onSurface
                                        : colors.onSurface
                                            .withValues(alpha: 0.3),
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
                              hasValue
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 16,
                              color: hasValue ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
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

  /// Aperçu des 2 expériences les plus récentes en frise chronologique
  /// (pastille + ligne verticale), plus "Voir tout" qui ouvre le formulaire
  /// complet (édition/ajout/suppression) — cf. maquette fournie. Le détail
  /// intégral n'a pas besoin d'un écran dédié : le formulaire d'édition en
  /// tient déjà lieu.
  Widget _buildExperiencesSection(
      BuildContext context, ColorScheme colors, dynamic model) {
    const accentColor = Color(0xFF3B82F6);
    final allExperiences = model.experiences as List;

    final sorted = [...allExperiences]..sort((a, b) {
        final startA = DateTime.tryParse(a.startDate ?? '');
        final startB = DateTime.tryParse(b.startDate ?? '');
        if (startA == null || startB == null) return 0;
        return startB.compareTo(startA);
      });
    final preview = sorted.take(2).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline_rounded,
                      size: 16, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Expériences',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface),
                  ),
                ),
                if (allExperiences.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _openForm(context,
                        section: 'experiences', addOnly: true),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.add_rounded,
                          size: 16, color: accentColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showAllExperiences(
                        context, colors, sorted, allExperiences),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: accentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (allExperiences.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.work_outline_rounded,
                      size: 18, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucune expérience ajoutée',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openForm(context,
                        section: 'experiences', addOnly: true),
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Ajouter',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: preview.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exp = entry.value;
                  return _ExperienceTimelineItem(
                    title: exp.title ?? '',
                    company: exp.company ?? '',
                    period: _formatExperiencePeriod(exp.startDate, exp.endDate),
                    description: exp.description ?? '',
                    isLast: i == preview.length - 1,
                    accentColor: accentColor,
                    colors: colors,
                    // editIndex : modifier/supprimer CETTE expérience
                    // précise, pas la liste complète (cf. doc de
                    // CompletionFormPage.editIndex).
                    onTap: () => _openForm(
                      context,
                      section: 'experiences',
                      editIndex: allExperiences.indexOf(exp),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Liste complète des expériences en lecture seule (frise chronologique),
  /// ouverte via "Voir tout" — même présentation (bandeau tiré vers le
  /// haut, poignée, titre) que "Paramètres" dans ProfilePage, plutôt que le
  /// formulaire d'édition : consulter tout l'historique ne doit pas forcer
  /// à passer par un écran d'édition. Un tap sur une entrée ouvre quand
  /// même le formulaire, pour modifier/supprimer celle-ci.
  void _showAllExperiences(BuildContext context, ColorScheme colors,
      List<dynamic> sorted, List<dynamic> allExperiences) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Expériences',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                return _ExperienceTimelineItem(
                  title: exp.title ?? '',
                  company: exp.company ?? '',
                  period: _formatExperiencePeriod(exp.startDate, exp.endDate),
                  description: exp.description ?? '',
                  isLast: i == sorted.length - 1,
                  accentColor: const Color(0xFF3B82F6),
                  colors: colors,
                  onTap: () => _openForm(
                    context,
                    section: 'experiences',
                    editIndex: allExperiences.indexOf(exp),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// "2023 – Aujourd'hui" / "2021 – 2023" — n'affiche que l'année (comme la
  /// maquette), à partir des dates complètes stockées côté backend.
  String _formatExperiencePeriod(String? start, String? end) {
    final startYear = _experienceYear(start);
    final endYear =
        (end != null && end.isNotEmpty) ? _experienceYear(end) : null;
    return '$startYear – ${endYear ?? "Aujourd'hui"}';
  }

  String _experienceYear(String? date) {
    if (date == null || date.isEmpty) return '';
    final parsed = DateTime.tryParse(date);
    return parsed != null ? parsed.year.toString() : date;
  }

  Widget _buildEducationsSection(
      BuildContext context, ColorScheme colors, dynamic model) {
    final allEducations = model.educations as List;
    // Plus récente en premier — même logique que les expériences.
    final educations = [...allEducations]
      ..sort((a, b) => (b.startYear ?? 0).compareTo(a.startYear ?? 0));

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
            onAddTap: () =>
                _openForm(context, section: 'educations', addOnly: true),
            expanded: _educationsExpanded,
            onToggle: () =>
                setState(() => _educationsExpanded = !_educationsExpanded),
          ),
          if (_educationsExpanded) ...[
            if (educations.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 18, color: Colors.orange),
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
                        child: Divider(
                            height: 1,
                            color: colors.onSurface.withValues(alpha: 0.05)),
                      ),
                    // Tap = ouvrir le formulaire complet pour modifier ou
                    // supprimer cette formation (seul moyen d'y accéder :
                    // le "+" de l'en-tête n'ouvre plus qu'une carte vierge,
                    // cf. addOnly sur CompletionFormPage).
                    InkWell(
                      onTap: () => _openForm(
                        context,
                        section: 'educations',
                        editIndex: allEducations.indexOf(edu),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.school_outlined,
                                  size: 18, color: Color(0xFF8B5CF6)),
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6)
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(6),
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
                                      if (field.isNotEmpty)
                                        const SizedBox(width: 8),
                                      Text(
                                        '$startYear - $endYear',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: colors.onSurface.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
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
                    const Icon(Icons.psychology_outlined,
                        size: 18, color: Colors.orange),
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
                      .map((s) => SkillChip(
                          label: s.name, subtitle: levelLabel(s.level)))
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

  /// "Centre d'intérêt" — mots-clés libres (loisirs, passions...). Même
  /// widget [SkillChip] que "Compétences" (couleur distincte pour les
  /// différencier), affiché aussi en lecture seule (sans onDelete) sur la
  /// carte publique consultée depuis Explorer — cf. PublicCardPage.
  Widget _buildInterestsSection(
    BuildContext context,
    ColorScheme colors,
    List<String> interests,
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
            icon: Icons.interests_outlined,
            title: "Centre d'intérêt",
            onAddTap: () => _openInterestsEditor(context),
            expanded: _interestsExpanded,
            onToggle: () =>
                setState(() => _interestsExpanded = !_interestsExpanded),
          ),
          if (_interestsExpanded) ...[
            if (interests.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.interests_outlined,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      "Aucun centre d'intérêt ajouté",
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
                  children: interests
                      .map((interest) => SkillChip(
                          label: interest, color: _interestsAccentColor))
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _openInterestsEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          const InterestsEditorSheet(companyColor: _interestsAccentColor),
    );
  }
}

class _CheckItem {
  final String label;
  final String? value;
  final IconData icon;
  const _CheckItem(this.label, this.value, this.icon);
}

/// Une ligne de la frise "Expériences" — pastille + ligne verticale reliée
/// à l'élément suivant (absente sur le dernier), titre/entreprise/période/
/// description, chevron à droite. Tap = ouvrir le formulaire d'édition.
class _ExperienceTimelineItem extends StatelessWidget {
  final String title;
  final String company;
  final String period;
  final String description;
  final bool isLast;
  final Color accentColor;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _ExperienceTimelineItem({
    required this.title,
    required this.company,
    required this.period,
    required this.description,
    required this.isLast,
    required this.accentColor,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastille + ligne verticale — la ligne s'étire (Expanded) sur
            // toute la hauteur du contenu à droite, IntrinsicHeight lui
            // donnant la mesure exacte (padding bas inclus) sans avoir à
            // calculer une hauteur à la main.
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: accentColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 4 : 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            period,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

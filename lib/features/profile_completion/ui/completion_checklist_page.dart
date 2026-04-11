import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_completion_provider.dart';
import 'completion_form_page.dart';

class CompletionChecklistPage extends StatelessWidget {
  const CompletionChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfileCompletionProvider>().model;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complétion du profil',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Bouton pour aller au formulaire
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const CompletionFormPage(),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildScoreCard(context, model, colors),
          const SizedBox(height: 24),

          _buildSection(
            context,
            colors: colors,
            icon: Icons.person_outline,
            title: 'Informations de base',
            onAddTap: () => _openForm(context),
            items: [
              _CheckItem('Poste', model.jobTitle, Icons.work_outline),
              _CheckItem('Entreprise', model.company, Icons.business_outlined),
              _CheckItem('Téléphone', model.phone, Icons.phone_outlined),
              _CheckItem('Email', model.email, Icons.email_outlined),
            ],
          ),
          const SizedBox(height: 16),

          _buildSection(
            context,
            colors: colors,
            icon: Icons.share_outlined,
            title: 'Réseaux sociaux',
            onAddTap: () => _openForm(context),
            items: [
              _CheckItem('LinkedIn', model.linkedin, Icons.work_outline),
              _CheckItem('Instagram', model.instagram, Icons.camera_alt_outlined),
              _CheckItem('GitHub', model.github, Icons.code),
              _CheckItem('Facebook', model.facebook, Icons.facebook),
              _CheckItem('Site web', model.website, Icons.language),
            ],
          ),
          const SizedBox(height: 16),

          // Section Expériences avec éléments détaillés
          _buildExperiencesSection(context, colors, model),
          const SizedBox(height: 16),

          // Section Formation avec éléments détaillés
          _buildEducationsSection(context, colors, model),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CompletionFormPage(),
    );
  }

  Widget _buildScoreCard(BuildContext context, dynamic model, ColorScheme colors) {
    final items = [
      model.jobTitle, model.company, model.phone, model.email,
      model.linkedin, model.instagram, model.github, model.facebook, model.website,
    ];
    final filled = items.where((v) => v != null && v.toString().trim().isNotEmpty).length;
    final total = items.length;
    final percent = filled / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.12),
            const Color(0xFF8B5CF6).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF3B82F6), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil complété à ${(percent * 100).round()}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$filled/$total informations renseignées',
                      style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              // Bouton modifier
              GestureDetector(
                onTap: () => _openForm(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: colors.onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
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
          Padding(
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
                // Bouton + pour naviguer vers le formulaire
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
              ],
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, size: 16, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Expériences',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openForm(context),
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
              ],
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_outlined, size: 16, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Formation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openForm(context),
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
              ],
            ),
          ),
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
      ),
    );
  }
}

class _CheckItem {
  final String label;
  final String? value;
  final IconData icon;
  const _CheckItem(this.label, this.value, this.icon);
}
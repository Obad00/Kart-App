import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_completion_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../model/profile_completion_model.dart';

class CompletionFormPage extends StatefulWidget {
  const CompletionFormPage({super.key});

  @override
  State<CompletionFormPage> createState() => _CompletionFormPageState();
}

class _CompletionFormPageState extends State<CompletionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _jobCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  final Map<String, bool> _activeFields = {
    'phone': false,
    'email': false,
    'linkedin': false,
    'instagram': false,
    'github': false,
    'facebook': false,
    'website': false,
  };

  final List<Map<String, TextEditingController>> _experiences = [];
  final List<Map<String, TextEditingController>> _educations = [];

  bool loading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final p = context.read<ProfileCompletionProvider>();
      await p.load();
      if (!mounted) return;

      final m = p.model;
      _jobCtrl.text = m.jobTitle ?? '';
      _companyCtrl.text = m.company ?? '';
      _phoneCtrl.text = m.phone ?? '';
      _emailCtrl.text = m.email ?? '';
      _linkedinCtrl.text = m.linkedin ?? '';
      _instagramCtrl.text = m.instagram ?? '';
      _githubCtrl.text = m.github ?? '';
      _facebookCtrl.text = m.facebook ?? '';
      _websiteCtrl.text = m.website ?? '';

      for (final field in m.activatedFields) {
        if (_activeFields.containsKey(field)) {
          _activeFields[field] = true;
        }
      }

      for (final exp in m.experiences) {
        _experiences.add({
          'title': TextEditingController(text: exp.title),
          'company': TextEditingController(text: exp.company),
          'start_date': TextEditingController(text: exp.startDate),
          'end_date': TextEditingController(text: exp.endDate ?? ''),
          'description': TextEditingController(text: exp.description),
        });
      }

      for (final edu in m.educations) {
        _educations.add({
          'school': TextEditingController(text: edu.school),
          'degree': TextEditingController(text: edu.degree),
          'field': TextEditingController(text: edu.field),
          'start_year': TextEditingController(text: edu.startYear.toString()),
          'end_year': TextEditingController(text: edu.endYear.toString()),
        });
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    _instagramCtrl.dispose();
    _githubCtrl.dispose();
    _facebookCtrl.dispose();
    _websiteCtrl.dispose();
    for (final exp in _experiences) {
      for (final ctrl in exp.values) {
        ctrl.dispose();
      }
    }
    for (final edu in _educations) {
      for (final ctrl in edu.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void _addExperience() {
    setState(() {
      _experiences.add({
        'title': TextEditingController(),
        'company': TextEditingController(),
        'start_date': TextEditingController(),
        'end_date': TextEditingController(),
        'description': TextEditingController(),
      });
    });
  }

  void _removeExperience(int index) {
    setState(() {
      for (final ctrl in _experiences[index].values) {
        ctrl.dispose();
      }
      _experiences.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      _educations.add({
        'school': TextEditingController(),
        'degree': TextEditingController(),
        'field': TextEditingController(),
        'start_year': TextEditingController(),
        'end_year': TextEditingController(),
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      for (final ctrl in _educations[index].values) {
        ctrl.dispose();
      }
      _educations.removeAt(index);
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initial = DateTime.now();
    if (controller.text.isNotEmpty) {
      final parsed = DateTime.tryParse(controller.text);
      if (parsed != null) initial = parsed;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _pickYear(TextEditingController controller) async {
    final now = DateTime.now();
    int selectedYear = int.tryParse(controller.text) ?? now.year;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une année'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(1970),
            lastDate: DateTime(2050),
            selectedDate: DateTime(selectedYear),
            onChanged: (DateTime dateTime) {
              controller.text = dateTime.year.toString();
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      _successMessage = null;
      _errorMessage = null;
    });

    final p = context.read<ProfileCompletionProvider>();

    final experiences = _experiences.map((exp) {
      return ExperienceModel(
        title: exp['title']!.text,
        company: exp['company']!.text,
        startDate: exp['start_date']!.text,
        endDate: exp['end_date']!.text.isEmpty ? null : exp['end_date']!.text,
        description: exp['description']!.text,
      );
    }).toList();

    final educations = _educations.map((edu) {
      return EducationModel(
        school: edu['school']!.text,
        degree: edu['degree']!.text,
        field: edu['field']!.text,
        startYear: int.tryParse(edu['start_year']!.text) ?? 0,
        endYear: int.tryParse(edu['end_year']!.text) ?? 0,
      );
    }).toList();

    final updated = ProfileCompletionModel(
      jobTitle: _jobCtrl.text,
      company: _companyCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      linkedin: _linkedinCtrl.text,
      instagram: _instagramCtrl.text,
      github: _githubCtrl.text,
      facebook: _facebookCtrl.text,
      website: _websiteCtrl.text,
      experiences: experiences,
      educations: educations,
      activatedFields: _activeFields.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
    );

    try {
      final ok = await p.service.update(updated);

      if (!mounted) return;

      if (ok) p.updateModel(updated);

      setState(() {
        loading = false;
        _successMessage = ok ? 'Profil mis à jour avec succès' : null;
        _errorMessage = ok ? null : 'Une erreur est survenue';
      });

      if (ok) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        _errorMessage = 'Erreur serveur. Veuillez réessayer.';
      });
      debugPrint('Profile update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, scrollController) => Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Compléter mon profil',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Renseignez vos informations',
                        style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_successMessage != null)
                _buildAlert(
                    _successMessage!, Colors.green, Icons.check_circle_outline),
              if (_errorMessage != null)
                _buildAlert(_errorMessage!, Colors.red, Icons.error_outline),
              _buildSectionHeader(
                  colors, Icons.person_outline, 'Informations de base'),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Poste',
                  controller: _jobCtrl,
                  prefixIcon: Icons.work_outline,
                  hint: 'Ex: Développeur Flutter'),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Entreprise',
                  controller: _companyCtrl,
                  prefixIcon: Icons.business_outlined,
                  hint: 'Nom de votre entreprise'),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Téléphone',
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: 'Ex: +221 77 123 45 67'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher le téléphone sur ma carte',
                value: _activeFields['phone'] ?? false,
                onChanged: (v) => setState(() => _activeFields['phone'] = v),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'votre@email.com'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher l\'email sur ma carte',
                value: _activeFields['email'] ?? false,
                onChanged: (v) => setState(() => _activeFields['email'] = v),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                  colors, Icons.share_outlined, 'Réseaux sociaux'),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'LinkedIn',
                  controller: _linkedinCtrl,
                  prefixIcon: Icons.work_outline,
                  hint: 'https://linkedin.com/in/...'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher LinkedIn sur ma carte',
                value: _activeFields['linkedin'] ?? false,
                onChanged: (v) => setState(() => _activeFields['linkedin'] = v),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Instagram',
                  controller: _instagramCtrl,
                  prefixIcon: Icons.camera_alt_outlined,
                  hint: 'https://instagram.com/...'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher Instagram sur ma carte',
                value: _activeFields['instagram'] ?? false,
                onChanged: (v) =>
                    setState(() => _activeFields['instagram'] = v),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'GitHub',
                  controller: _githubCtrl,
                  prefixIcon: Icons.code,
                  hint: 'https://github.com/...'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher GitHub sur ma carte',
                value: _activeFields['github'] ?? false,
                onChanged: (v) => setState(() => _activeFields['github'] = v),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Facebook',
                  controller: _facebookCtrl,
                  prefixIcon: Icons.facebook,
                  hint: 'https://facebook.com/...'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher Facebook sur ma carte',
                value: _activeFields['facebook'] ?? false,
                onChanged: (v) => setState(() => _activeFields['facebook'] = v),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                  label: 'Site web',
                  controller: _websiteCtrl,
                  prefixIcon: Icons.language,
                  hint: 'https://votresite.com'),
              const SizedBox(height: 8),
              _buildPremiumSwitch(
                title: 'Afficher le site web sur ma carte',
                value: _activeFields['website'] ?? false,
                onChanged: (v) => setState(() => _activeFields['website'] = v),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(
                colors,
                Icons.history,
                'Expériences',
                trailing: _buildAddButton(_addExperience),
              ),
              const SizedBox(height: 12),
              if (_experiences.isEmpty)
                _buildEmptyState(colors, 'Aucune expérience',
                    'Ajoutez votre première expérience', Icons.work_outline),
              ..._experiences.asMap().entries.map((entry) {
                return _buildExperienceCard(colors, entry.key, entry.value);
              }),
              const SizedBox(height: 24),
              _buildSectionHeader(
                colors,
                Icons.school_outlined,
                'Formation',
                trailing: _buildAddButton(_addEducation),
              ),
              const SizedBox(height: 12),
              if (_educations.isEmpty)
                _buildEmptyState(colors, 'Aucune formation',
                    'Ajoutez votre première formation', Icons.school_outlined),
              ..._educations.asMap().entries.map((entry) {
                return _buildEducationCard(colors, entry.key, entry.value);
              }),
              const SizedBox(height: 32),
              AuthPrimaryButton(
                label: 'Sauvegarder',
                loading: loading,
                onTap: _save,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceCard(
    ColorScheme colors,
    int index,
    Map<String, TextEditingController> exp,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_outline,
                    size: 16, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 10),
              Text(
                'Expérience ${index + 1}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeExperience(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthTextField(
              label: 'Titre du poste',
              controller: exp['title']!,
              prefixIcon: Icons.badge_outlined,
              hint: 'Ex: Développeur Senior'),
          const SizedBox(height: 10),
          AuthTextField(
              label: 'Entreprise',
              controller: exp['company']!,
              prefixIcon: Icons.business_outlined,
              hint: "Nom de l'entreprise"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(exp['start_date']!),
                  child: AbsorbPointer(
                    child: AuthTextField(
                        label: 'Date début',
                        controller: exp['start_date']!,
                        prefixIcon: Icons.calendar_today_outlined,
                        hint: 'Sélectionner'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(exp['end_date']!),
                  child: AbsorbPointer(
                    child: AuthTextField(
                        label: 'Date fin',
                        controller: exp['end_date']!,
                        prefixIcon: Icons.calendar_today_outlined,
                        hint: 'Présent'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AuthTextField(
              label: 'Description',
              controller: exp['description']!,
              prefixIcon: Icons.description_outlined,
              hint: 'Décrivez vos responsabilités...'),
        ],
      ),
    );
  }

  Widget _buildEducationCard(
    ColorScheme colors,
    int index,
    Map<String, TextEditingController> edu,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_outlined,
                    size: 16, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 10),
              Text(
                'Formation ${index + 1}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B5CF6)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _removeEducation(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthTextField(
              label: 'École / Université',
              controller: edu['school']!,
              prefixIcon: Icons.school_outlined,
              hint: "Nom de l'établissement"),
          const SizedBox(height: 10),
          AuthTextField(
              label: 'Diplôme',
              controller: edu['degree']!,
              prefixIcon: Icons.workspace_premium_outlined,
              hint: 'Ex: Master, Licence...'),
          const SizedBox(height: 10),
          AuthTextField(
              label: 'Domaine',
              controller: edu['field']!,
              prefixIcon: Icons.category_outlined,
              hint: 'Ex: Informatique, Marketing...'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickYear(edu['start_year']!),
                  child: AbsorbPointer(
                    child: AuthTextField(
                        label: 'Année début',
                        controller: edu['start_year']!,
                        prefixIcon: Icons.calendar_today_outlined,
                        hint: 'Sélectionner'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickYear(edu['end_year']!),
                  child: AbsorbPointer(
                    child: AuthTextField(
                        label: 'Année fin',
                        controller: edu['end_year']!,
                        prefixIcon: Icons.calendar_today_outlined,
                        hint: 'Sélectionner'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    ColorScheme colors,
    IconData icon,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildAddButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Color(0xFF3B82F6)),
            SizedBox(width: 4),
            Text(
              'Ajouter',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ColorScheme colors,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.25)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.4)),
              ),
              Text(
                subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
            : colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
              : colors.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: value
                    ? const Color(0xFF3B82F6)
                    : colors.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveThumbColor: colors.onSurface.withValues(alpha: 0.4),
              inactiveTrackColor: colors.onSurface.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

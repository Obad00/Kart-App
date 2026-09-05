import 'package:flutter/material.dart';
import '../model/job_filters.dart';
import '../providers/jobmatch_provider.dart';

const _accentBlue = Color(0xFF3B82F6);

/// Feuille de filtres du fil JobMatch (cf. maquette fournie) — Domaine,
/// Localisation, Télétravail, Type de contrat, Niveau d'expérience,
/// Salaire, Compétences, Date de publication. "Fonction" de la maquette
/// n'a pas d'équivalent ici : aucun champ dédié côté offre (juste le titre
/// en texte libre), l'ajouter aurait voulu dire un picker qui ne filtre
/// concrètement rien.
Future<void> showJobFiltersSheet(
  BuildContext context,
  JobMatchProvider provider,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _JobFiltersSheet(provider: provider),
  );
}

class _JobFiltersSheet extends StatefulWidget {
  final JobMatchProvider provider;

  const _JobFiltersSheet({required this.provider});

  @override
  State<_JobFiltersSheet> createState() => _JobFiltersSheetState();
}

class _JobFiltersSheetState extends State<_JobFiltersSheet> {
  late JobMatchFilters _draft;

  static const _experienceLevels = [
    (label: 'Débutant (0-2 ans)', value: 0),
    (label: 'Intermédiaire (3-5 ans)', value: 3),
    (label: 'Confirmé (5+ ans)', value: 5),
  ];

  static const _publishedWithinOptions = [
    (label: "Aujourd'hui", value: 1),
    (label: 'Cette semaine', value: 7),
    (label: 'Ce mois-ci', value: 30),
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.provider.filters;
    widget.provider.loadFilterOptions();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final options = widget.provider.filterOptions;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                  child: Row(
                    children: [
                      Text(
                        'Filtres',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            setState(() => _draft = const JobMatchFilters()),
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildRow(
                          colors,
                          icon: Icons.category_outlined,
                          label: 'Domaine',
                          value: _draft.categoryName ?? 'Indifférent',
                          onTap: options == null
                              ? null
                              : () async {
                                  final picked =
                                      await _pickString<JobCategoryOption>(
                                    context,
                                    title: 'Domaine',
                                    options: options.categories,
                                    labelOf: (c) => c.name,
                                  );
                                  if (picked == null) return;
                                  setState(() {
                                    _draft = _draft.copyWith(
                                      categoryId: picked.id,
                                      categoryName: picked.name,
                                    );
                                  });
                                },
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.location_on_outlined,
                          label: 'Localisation',
                          value: _draft.location ?? 'Indifférent',
                          onTap: options == null
                              ? null
                              : () async {
                                  final picked = await _pickString<String>(
                                    context,
                                    title: 'Localisation',
                                    options: options.locations,
                                    labelOf: (s) => s,
                                  );
                                  if (picked == null) return;
                                  setState(() => _draft =
                                      _draft.copyWith(location: picked));
                                },
                        ),
                        _buildSwitchRow(
                          colors,
                          icon: Icons.home_work_outlined,
                          label: 'Télétravail uniquement',
                          value: _draft.remoteOnly,
                          onChanged: (v) => setState(
                              () => _draft = _draft.copyWith(remoteOnly: v)),
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.description_outlined,
                          label: 'Type de contrat',
                          value: _draft.contractType ?? 'Indifférent',
                          onTap: options == null
                              ? null
                              : () async {
                                  final picked = await _pickString<String>(
                                    context,
                                    title: 'Type de contrat',
                                    options: options.contractTypes,
                                    labelOf: (s) => s,
                                  );
                                  if (picked == null) return;
                                  setState(() => _draft =
                                      _draft.copyWith(contractType: picked));
                                },
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.trending_up_rounded,
                          label: "Niveau d'expérience",
                          value: _experienceLevels
                                  .where((e) => e.value == _draft.minExperience)
                                  .map((e) => e.label)
                                  .firstOrNull ??
                              'Indifférent',
                          onTap: () async {
                            final picked = await _pickString(
                              context,
                              title: "Niveau d'expérience",
                              options: _experienceLevels,
                              labelOf: (e) => e.label,
                            );
                            if (picked == null) return;
                            setState(() => _draft =
                                _draft.copyWith(minExperience: picked.value));
                          },
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.attach_money_rounded,
                          label: 'Salaire minimum',
                          value: _draft.minSalary != null
                              ? '${_draft.minSalary} FCFA'
                              : 'Indifférent',
                          onTap: () => _pickSalary(context),
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.psychology_outlined,
                          label: 'Compétences',
                          value: _draft.skillNames.isEmpty
                              ? 'Indifférent'
                              : _draft.skillNames.join(', '),
                          onTap: options == null
                              ? null
                              : () => _pickSkills(context, options.skills),
                        ),
                        _buildRow(
                          colors,
                          icon: Icons.event_outlined,
                          label: 'Date de publication',
                          value: _publishedWithinOptions
                                  .where((e) =>
                                      e.value == _draft.publishedWithinDays)
                                  .map((e) => e.label)
                                  .firstOrNull ??
                              'Indifférent',
                          onTap: () async {
                            final picked = await _pickString(
                              context,
                              title: 'Date de publication',
                              options: _publishedWithinOptions,
                              labelOf: (e) => e.label,
                            );
                            if (picked == null) return;
                            setState(() => _draft = _draft.copyWith(
                                publishedWithinDays: picked.value));
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.provider.applyFilters(_draft);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _draft.isEmpty
                            ? 'Voir les opportunités'
                            : 'Appliquer (${_draft.activeCount})',
                        style: const TextStyle(
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
      },
    );
  }

  Widget _buildRow(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 20, color: colors.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14.5, color: colors.onSurface),
              ),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: value == 'Indifférent'
                      ? colors.onSurface.withValues(alpha: 0.4)
                      : _accentBlue,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: colors.onSurface.withValues(alpha: 0.3)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14.5, color: colors.onSurface),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _accentBlue,
          ),
        ],
      ),
    );
  }

  Future<T?> _pickString<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
  }) {
    final colors = Theme.of(context).colorScheme;
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options
                      .map((o) => ListTile(
                            title: Text(labelOf(o)),
                            onTap: () => Navigator.pop(sheetContext, o),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSalary(BuildContext context) async {
    final controller = TextEditingController(
      text: _draft.minSalary?.toString() ?? '',
    );
    final colors = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salaire minimum (FCFA)',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'ex: 500000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                      sheetContext, int.tryParse(controller.text.trim())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Valider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (result == null) {
      setState(() => _draft = _draft.copyWith(clearMinSalary: true));
    } else {
      setState(() => _draft = _draft.copyWith(minSalary: result));
    }
  }

  Future<void> _pickSkills(
    BuildContext context,
    List<JobSkillOption> allSkills,
  ) async {
    var selected = Set<int>.from(_draft.skillIds);
    final colors = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compétences',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allSkills.map((skill) {
                        final isSelected = selected.contains(skill.id);
                        return FilterChip(
                          label: Text(skill.name),
                          selected: isSelected,
                          onSelected: (v) => setSheetState(() {
                            if (v) {
                              selected.add(skill.id);
                            } else {
                              selected.remove(skill.id);
                            }
                          }),
                          selectedColor: _accentBlue.withValues(alpha: 0.15),
                          checkmarkColor: _accentBlue,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final names = allSkills
                          .where((s) => selected.contains(s.id))
                          .map((s) => s.name)
                          .toList();
                      setState(() {
                        _draft = _draft.copyWith(
                          skillIds: selected.toList(),
                          skillNames: names,
                        );
                      });
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Valider'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

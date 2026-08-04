import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../model/skill_model.dart';
import '../providers/candidate_skills_provider.dart';

const _levels = [
  {'value': 'debutant', 'label': 'Débutant'},
  {'value': 'intermediaire', 'label': 'Intermédiaire'},
  {'value': 'confirme', 'label': 'Confirmé'},
  {'value': 'expert', 'label': 'Expert'},
];

String levelLabel(String level) {
  return _levels.firstWhere(
        (l) => l['value'] == level,
        orElse: () => _levels[1],
      )['label'] as String;
}

class SkillEditorSheet extends StatefulWidget {
  const SkillEditorSheet({super.key});

  @override
  State<SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends State<SkillEditorSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<SkillSuggestion> _results = [];
  bool _searching = false;
  bool _saving = false;
  late List<CandidateSkillModel> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<CandidateSkillModel>.from(
      context.read<CandidateSkillsProvider>().skills,
    );
    // Affiche les compétences les plus utilisées dès l'ouverture, avant
    // même de taper (le backend renvoie déjà un top-20 par défaut).
    _performSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    // Une recherche vide renvoie les compétences les plus utilisées du
    // référentiel (déjà géré côté backend) — permet d'afficher une liste
    // avant même de taper.
    final trimmed = query.trim();

    setState(() => _searching = true);
    try {
      final results = await context.read<CandidateSkillsProvider>().service.search(trimmed);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  bool _isSelected(SkillSuggestion suggestion) {
    return _selected.any((s) => s.id == suggestion.id);
  }

  bool get _exactMatchExists {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _results.any((r) => r.name.trim().toLowerCase() == query);
  }

  Future<void> _toggleSuggestion(SkillSuggestion suggestion) async {
    if (_isSelected(suggestion)) {
      setState(() => _selected.removeWhere((s) => s.id == suggestion.id));
      return;
    }

    final level = await _pickLevel(context);
    if (level == null) return;

    setState(() {
      _selected.add(CandidateSkillModel.fromSuggestion(suggestion, level: level));
      _searchCtrl.clear();
      _results = [];
    });
  }

  Future<void> _addFreeText() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    final level = await _pickLevel(context);
    if (level == null) return;

    setState(() {
      _selected.add(CandidateSkillModel(name: query, level: level));
      _searchCtrl.clear();
      _results = [];
    });
  }

  void _removeSelected(CandidateSkillModel skill) {
    setState(() => _selected.remove(skill));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<CandidateSkillsProvider>().save(_selected);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const blueColor = Color(0xFF3B82F6);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Compétences',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AuthTextField(
                label: 'Rechercher une compétence',
                hint: 'React, Comptabilité, Anglais...',
                controller: _searchCtrl,
                prefixIcon: Icons.search,
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      if (_results.isNotEmpty) _buildResults(colors),
                      // Toujours proposé, même s'il y a des suggestions :
                      // l'utilisateur peut vouloir saisir une compétence
                      // absente du référentiel.
                      if (_searchCtrl.text.trim().isNotEmpty && !_exactMatchExists)
                      GestureDetector(
                        onTap: _addFreeText,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: blueColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: blueColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_rounded, size: 18, color: blueColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ajouter "${_searchCtrl.text.trim()}"',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: blueColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Text(
                      'Sélectionnées (${_selected.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selected.isEmpty)
                      Text(
                        'Aucune compétence sélectionnée pour le moment',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selected
                            .map((s) => SkillChip(
                                  label: s.name,
                                  subtitle: levelLabel(s.level),
                                  onDelete: () => _removeSelected(s),
                                ))
                            .toList(),
                      ),
                    if (_selected.length < 5) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Ajoutez au moins 5 compétences pour un meilleur matching.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AuthPrimaryButton(
                label: 'Enregistrer',
                loading: _saving,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ColorScheme colors) {
    final grouped = <String, List<SkillSuggestion>>{};
    for (final result in _results) {
      grouped.putIfAbsent(result.category ?? 'Autres', () => []).add(result);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((suggestion) {
                  final selected = _isSelected(suggestion);
                  return GestureDetector(
                    onTap: () => _toggleSuggestion(suggestion),
                    child: SkillChip(
                      label: suggestion.name,
                      color: selected ? Colors.green : const Color(0xFF3B82F6),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

const _levelDescriptions = {
  'debutant': 'Notions de base, en apprentissage',
  'intermediaire': 'À l\'aise sur les tâches courantes',
  'confirme': 'Autonome, bonne maîtrise',
  'expert': 'Référent, maîtrise avancée',
};

Future<String?> _pickLevel(BuildContext context) {
  const accentBlue = Color(0xFF3B82F6);

  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Quel est votre niveau ?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ..._levels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;
                final value = level['value'] as String;
                final label = level['label'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: accentBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentBlue.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(4, (i) {
                              return Container(
                                margin: const EdgeInsets.only(right: 3),
                                width: 5,
                                height: 10.0 + (i * 5),
                                decoration: BoxDecoration(
                                  color: i <= index
                                      ? accentBlue
                                      : colors.onSurface.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _levelDescriptions[value] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurface.withValues(alpha: 0.5),
                                  ),
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
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

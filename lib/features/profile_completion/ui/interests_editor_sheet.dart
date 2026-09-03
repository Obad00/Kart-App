import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../../digital_card/providers/card_provider.dart';
import '../model/interest_model.dart';
import '../providers/profile_completion_provider.dart';
import '../services/interest_service.dart';

/// Bottom sheet "Centre d'intérêt" — mots-clés libres (loisirs, passions...)
/// affichés en tête du profil et, en lecture seule, sur la carte publique
/// (page de détail ouverte depuis Explorer). Le champ reste du texte libre
/// à l'enregistrement : le référentiel (InterestController) ne sert qu'à
/// suggérer pendant la saisie, même principe que SkillEditorSheet.
class InterestsEditorSheet extends StatefulWidget {
  final Color companyColor;

  const InterestsEditorSheet({super.key, required this.companyColor});

  @override
  State<InterestsEditorSheet> createState() => _InterestsEditorSheetState();
}

class _InterestsEditorSheetState extends State<InterestsEditorSheet> {
  static const _maxInterests = 20;

  final _inputCtrl = TextEditingController();
  final _service = InterestService();
  late List<String> _interests;
  Timer? _debounce;
  List<InterestSuggestion> _results = [];
  bool _searching = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _interests = List<String>.from(
      context.read<ProfileCompletionProvider>().model.interests,
    );
    // Affiche les centres d'intérêt les plus utilisés dès l'ouverture,
    // avant même de taper (le backend renvoie déjà un top par défaut).
    _performSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged(String value) {
    setState(() {}); // pour le bouton "+" et le compteur
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _performSearch(value));
  }

  Future<void> _performSearch(String query) async {
    setState(() => _searching = true);
    try {
      final results = await _service.search(query.trim());
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

  void _addInterest([String? raw]) {
    final value = (raw ?? _inputCtrl.text).trim();
    if (value.isEmpty) return;

    final alreadyExists =
        _interests.any((e) => e.toLowerCase() == value.toLowerCase());
    if (alreadyExists) {
      _inputCtrl.clear();
      return;
    }
    if (_interests.length >= _maxInterests) {
      setState(() => _error = "Maximum $_maxInterests centres d'intérêt.");
      return;
    }

    setState(() {
      _interests.add(value);
      _inputCtrl.clear();
      _error = null;
    });
    // Réaffiche le top (comme à l'ouverture) pour continuer à en choisir
    // d'autres, plutôt que de laisser les résultats de la recherche
    // précédente affichés pour rien.
    _performSearch('');
  }

  void _removeInterest(String value) {
    setState(() => _interests.remove(value));
  }

  bool _isSelected(InterestSuggestion suggestion) {
    return _interests
        .any((e) => e.toLowerCase() == suggestion.name.toLowerCase());
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final provider = context.read<ProfileCompletionProvider>();
    // Mutation directe (champ non final) : évite d'avoir à reconstruire un
    // ProfileCompletionModel complet en recopiant tous les autres champs à
    // la main (cf. le "piège" corrigé dans CompletionFormPage._save).
    provider.model.interests = _interests;
    final ok = await provider.save();

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _saving = false;
        _error = 'Une erreur est survenue, réessayez.';
      });
      return;
    }

    provider.updateModel(provider.model);
    // La carte du profil (en-tête) lit ses données depuis CardProvider, pas
    // ProfileCompletionProvider — même principe que la personnalisation de
    // carte (cf. updatePersonalBranding).
    await context.read<CardProvider>().loadCardSummary();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Même carcasse que SkillEditorSheet (Compétences) — hauteur fixe à
    // 85% de l'écran, coins arrondis en haut, poignée + titre/croix de
    // fermeture, champ de saisie fixe et bouton "Enregistrer" épinglé en
    // bas pendant que le reste défile — plutôt qu'un simple Padding qui
    // grandissait avec le contenu et perdait le fond/les coins arrondis.
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
                      "Centres d'intérêt",
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textInputAction: TextInputAction.done,
                      onChanged: _onInputChanged,
                      onSubmitted: _addInterest,
                      decoration: InputDecoration(
                        hintText: 'Ex: Voyage, Photographie...',
                        filled: true,
                        fillColor: colors.onSurface.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () => _addInterest(),
                    style: IconButton.styleFrom(
                      backgroundColor: widget.companyColor,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_results.isNotEmpty) ...[
                      _buildResults(colors),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      "Ajoutés (${_interests.length})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_interests.isEmpty)
                      Text(
                        "Aucun centre d'intérêt ajouté pour le moment.",
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withValues(alpha: 0.4),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interests
                            .map((interest) => SkillChip(
                                  label: interest,
                                  color: widget.companyColor,
                                  onDelete: () => _removeInterest(interest),
                                ))
                            .toList(),
                      ),
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
                icon: Icons.check_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestions du référentiel, groupées par catégorie — même présentation
  /// que SkillEditorSheet._buildResults. Un tap ajoute directement (déjà
  /// dédupliqué/plafonné par _addInterest).
  Widget _buildResults(ColorScheme colors) {
    final grouped = <String, List<InterestSuggestion>>{};
    for (final result in _results) {
      grouped.putIfAbsent(result.category ?? 'Autres', () => []).add(result);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
                    onTap:
                        selected ? null : () => _addInterest(suggestion.name),
                    child: SkillChip(
                      label: suggestion.name,
                      color: selected ? Colors.green : widget.companyColor,
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

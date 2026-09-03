import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../../digital_card/providers/card_provider.dart';
import '../providers/profile_completion_provider.dart';

/// Bottom sheet "Centre d'intérêt" — mots-clés libres (loisirs, passions...)
/// affichés en tête du profil et, en lecture seule, sur la carte publique
/// (page de détail ouverte depuis Explorer).
class InterestsEditorSheet extends StatefulWidget {
  final Color companyColor;

  const InterestsEditorSheet({super.key, required this.companyColor});

  @override
  State<InterestsEditorSheet> createState() => _InterestsEditorSheetState();
}

class _InterestsEditorSheetState extends State<InterestsEditorSheet> {
  static const _maxInterests = 20;

  final _inputCtrl = TextEditingController();
  late List<String> _interests;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _interests = List<String>.from(
      context.read<ProfileCompletionProvider>().model.interests,
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
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
  }

  void _removeInterest(String value) {
    setState(() => _interests.remove(value));
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

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.companyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.interests_outlined,
                    color: widget.companyColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Centres d'intérêt",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Loisirs, passions... affichés sur votre profil et votre carte publique.',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    textInputAction: TextInputAction.done,
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Enregistrer',
              loading: _saving,
              onTap: _save,
              icon: Icons.check_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

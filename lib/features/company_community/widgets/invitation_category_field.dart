import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_sheet.dart';
import '../services/event_invitations_service.dart';
import 'invitation_sheets.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Catégorie d'un invité : liste des catégories déjà utilisées pour
/// l'événement, « Aucune », ou « Nouvelle catégorie… » (saisie libre). Évite
/// les doublons « VIP » / « vip » d'un champ texte. La valeur choisie est
/// écrite dans [controller] (vide : aucune catégorie).
class InvitationCategoryField extends StatefulWidget {
  final TextEditingController controller;
  final EventInvitationsService service;
  final int eventId;
  final String placeholder;
  final bool dense;

  /// Appelé à chaque choix, avec « catégorie d'exposants ? » (numéro de stand).
  final ValueChanged<bool>? onExhibitorChanged;

  const InvitationCategoryField({
    super.key,
    required this.controller,
    required this.service,
    required this.eventId,
    this.placeholder = 'Catégorie (facultatif)',
    this.dense = false,
    this.onExhibitorChanged,
  });

  static bool isExhibitorName(String name, List<String> exhibitors) =>
      name.isNotEmpty && (exhibitors.contains(name) || RegExp(r'^expos', caseSensitive: false).hasMatch(name));

  @override
  State<InvitationCategoryField> createState() => _InvitationCategoryFieldState();
}

class _InvitationCategoryFieldState extends State<InvitationCategoryField> {
  List<String> _categories = [];
  List<String> _exhibitors = [];

  String get _value => widget.controller.text.trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.service.categories(widget.eventId);
      if (!mounted) return;
      setState(() {
        _categories = result.all;
        _exhibitors = result.exhibitors;
      });
      _notify();
    } catch (_) {
      // Sans la liste, « Nouvelle catégorie… » reste possible.
    }
  }

  void _notify() => widget.onExhibitorChanged?.call(InvitationCategoryField.isExhibitorName(_value, _exhibitors));

  void _set(String value) {
    setState(() => widget.controller.text = value.trim());
    _notify();
  }

  Future<void> _pick() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CategorySheet(categories: _categories, selected: _value),
    );
    if (!mounted || choice == null) return;
    if (choice == _CategorySheet.newCategory) {
      final created = await _askNewCategory();
      if (created != null && created.trim().isNotEmpty) _set(created);
      return;
    }
    _set(choice);
  }

  Future<String?> _askNewCategory() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex : Presse, Partenaire'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Valider')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final empty = _value.isEmpty;
    return Material(
      color: colors.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _pick,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.dense ? 12 : 16, vertical: widget.dense ? 12 : 16),
          child: Row(
            children: [
              Icon(Icons.sell_outlined, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  empty ? widget.placeholder : _value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.dense ? 14 : 15,
                    color: empty ? colors.onSurface.withValues(alpha: 0.5) : colors.onSurface,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: colors.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  static const newCategory = '\u0000new';

  final List<String> categories;
  final String selected;

  const _CategorySheet({required this.categories, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget option(String label, String value, {IconData? icon}) => ListTile(
          leading: icon != null ? Icon(icon, color: _themeBlue) : null,
          title: Text(label, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w600)),
          trailing: value == selected ? const Icon(Icons.check_rounded, color: _themeBlue) : null,
          onTap: () => Navigator.pop(context, value),
        );

    return GlassSheet(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            children: [
              const SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('Catégorie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
              ),
              option('Aucune', ''),
              for (final category in categories) option(category, category),
              option('Nouvelle catégorie…', newCategory, icon: Icons.add_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

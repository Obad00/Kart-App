import 'package:flutter/material.dart';
import 'contacts_grouped_view.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final GlobalKey<ContactsGroupedViewState> _contactsKey =
      GlobalKey<ContactsGroupedViewState>();
  final ValueNotifier<int> _selectedCountNotifier = ValueNotifier<int>(0);
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _selectedCountNotifier.dispose();
    super.dispose();
  }

  void _onSelectionChanged(int count) {
    _selectedCountNotifier.value = count;
    // Le mode sélection suit l'état réel de la sélection : sélectionner un
    // contact (même sans être passé par "Sélectionner" dans le menu) active
    // les contrôles, et revenir à 0 sélection les referme automatiquement
    // — avant, une fois activé, seul "Terminer la sélection" dans le menu
    // pouvait le refermer, même après avoir tout désélectionné.
    if (count == 0 || !_isSelectionMode) {
      setState(() => _isSelectionMode = count > 0);
    }
  }

  /// Annule complètement la sélection (vide la liste ET quitte le mode) —
  /// utilisé par "Terminer la sélection" et par le tap en dehors des
  /// contacts.
  void _cancelSelection() {
    _contactsKey.currentState?.clearSelection();
    setState(() => _isSelectionMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContactsGroupedView(
          key: _contactsKey,
          onSelectionChanged: _onSelectionChanged,
          selectionModeActive: _isSelectionMode,
          onEnterSelectionMode: () => setState(() => _isSelectionMode = true),
          onCancelSelection: _cancelSelection,
        ),
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _selectedCountNotifier,
        builder: (context, selectedCount, _) {
          const Color themeBlue = Color(0xFF3B82F6);

          if (!_isSelectionMode) {
            // La sélection démarre maintenant depuis le menu "..." en haut
            // de la page (Exporter/Sélectionner/Supprimer) — plus besoin
            // d'un bouton flottant ici. "Explorer" a sa propre entrée dans
            // la barre de navigation du bas.
            return const SizedBox.shrink();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton annuler
              FloatingActionButton.small(
                heroTag: 'cancel_selection',
                onPressed: _cancelSelection,
                backgroundColor: Colors.grey.withValues(alpha: 0.7),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // Bouton supprimer
              if (selectedCount > 0)
                FloatingActionButton.small(
                  heroTag: 'delete_contacts',
                  onPressed: () async {
                    await _contactsKey.currentState?.deleteSelectedContacts();
                    if (mounted) {
                      setState(() => _isSelectionMode = false);
                    }
                  },
                  backgroundColor: Colors.red,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 20),
                ),
              if (selectedCount > 0) const SizedBox(width: 12),
              // Bouton exporter
              FloatingActionButton.extended(
                heroTag: 'export_contacts',
                onPressed: selectedCount > 0
                    ? () async {
                        await _contactsKey.currentState
                            ?.exportSelectedContacts();
                        if (mounted) {
                          setState(() => _isSelectionMode = false);
                        }
                      }
                    : null,
                backgroundColor: selectedCount > 0
                    ? themeBlue
                    : Colors.grey.withValues(alpha: 0.5),
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                label: Text(
                  selectedCount > 0
                      ? 'Exporter ($selectedCount)'
                      : 'Sélectionner des contacts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.file_download_rounded,
                    color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
        ),
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _selectedCountNotifier,
        builder: (context, selectedCount, _) {
          const Color themeBlue = Color(0xFF3B82F6);

          if (!_isSelectionMode) {
            return FloatingActionButton(
              onPressed: () => setState(() => _isSelectionMode = true),
              backgroundColor: themeBlue,
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child:
                  const Icon(Icons.download_rounded, color: Colors.white),
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton annuler
              FloatingActionButton.small(
                heroTag: 'cancel_selection',
                onPressed: () {
                  widget.key;
                  _contactsKey.currentState?.clearSelection();
                  setState(() => _isSelectionMode = false);
                },
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
                    await _contactsKey.currentState
                        ?.deleteSelectedContacts();
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

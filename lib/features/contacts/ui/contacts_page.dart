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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: ContactsGroupedView(key: _contactsKey),
      ),
      floatingActionButton: _ExportFAB(contactsKey: _contactsKey),
    );
  }
}

class _ExportFAB extends StatefulWidget {
  final GlobalKey<ContactsGroupedViewState> contactsKey;

  const _ExportFAB({required this.contactsKey});

  @override
  State<_ExportFAB> createState() => _ExportFABState();
}

class _ExportFABState extends State<_ExportFAB> {
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    const Color themeBlue = Color(0xFF3B82F6);
    final selectedCount =
        widget.contactsKey.currentState?.selectedContacts.length ?? 0;

    if (!_isSelectionMode) {
      return FloatingActionButton(
        onPressed: () => setState(() => _isSelectionMode = true),
        backgroundColor: themeBlue,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.download_rounded, color: Colors.white),
      );
    }

    return FloatingActionButton.extended(
      onPressed: selectedCount > 0
          ? () async {
              await widget.contactsKey.currentState?.exportSelectedContacts();
              if (mounted) setState(() => _isSelectionMode = false);
            }
          : null,
      backgroundColor:
          selectedCount > 0 ? themeBlue : Colors.grey.withValues(alpha: 0.5),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      label: Text(
        selectedCount > 0
            ? 'Ajouter au device ($selectedCount)'
            : 'Sélectionner des contacts',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      icon: const Icon(Icons.file_download_rounded, color: Colors.white),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/contacts_provider.dart';
import '../widgets/contact_row.dart';
import '../widgets/contacts_search_bar.dart';

class ContactsGroupedView extends StatelessWidget {
  const ContactsGroupedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, _) {
        // ⏳ Loading
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ❌ Error
        if (provider.error != null) {
          return Center(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // 📭 EMPTY STATE (Aucun contact)
        if (provider.filteredGroups.isEmpty) {
          return _emptyState(context);
        }

        // ✅ Contacts list
        return Column(
          children: [
            /// 🔍 Search bar
            ContactsSearchBar(
              onChanged: provider.filterContacts,
            ),

            /// 📇 Grouped contacts
            Expanded(
              child: ListView.builder(
                itemCount: provider.filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = provider.filteredGroups[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🏷 Section header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          group.highlight.name,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                        ),
                      ),

                      /// 👤 Contacts
                      ...group.contacts.map(
                        (c) => ContactRow(contact: c),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ───────────────── EMPTY STATE UI ─────────────────

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scannez une carte ou partagez la vôtre pour commencer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
            onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité bientôt disponible'),
                  ),
                );
              },

              child: const Text('Partager ma carte'),
            ),
          ],
        ),
      ),
    );
  }
}

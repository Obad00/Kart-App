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
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        return Column(
          children: [
            /// 🔍 Search (style iOS)
            ContactsSearchBar(
              onChanged: provider.filterContacts,
            ),

            /// 📇 Contacts grouped
            Expanded(
              child: ListView.builder(
                itemCount: provider.filteredGroups.length,
                itemBuilder: (context, index) {
                  final group = provider.filteredGroups[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🏷 Highlight header (iOS section style)
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
}

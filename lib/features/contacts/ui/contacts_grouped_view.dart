import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/utils/company_color_helper.dart';
import '../../navigation/home_shell.dart';
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
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée avec cercles
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle externe
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: companyColor.withValues(alpha: 0.05),
                    ),
                  ),
                  // Cercle intermédiaire
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: companyColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // Icône centrale
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          companyColor.withValues(alpha: 0.2),
                          companyColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.people_outline_rounded,
                      size: 32,
                      color: companyColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Titre
            Text(
              'Aucun contact',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Description
            Text(
              'Scannez une carte ou partagez\nla vôtre pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurface.withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton Partager ma carte
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Naviguer vers la page Carte (index 0)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const HomeShell(initialIndex: 0),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      companyColor,
                      companyColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: companyColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Partager ma carte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

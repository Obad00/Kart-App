// ───────────────── ContactsGroupedView ─────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../shared/utils/company_color_helper.dart';
import '../../navigation/home_shell.dart';
import '../providers/contacts_provider.dart';
import '../widgets/contact_row.dart';
import '../widgets/contacts_search_bar.dart';

class ContactsGroupedView extends StatefulWidget {
  const ContactsGroupedView({super.key});

  @override
  State<ContactsGroupedView> createState() => _ContactsGroupedViewState();
}

class _ContactsGroupedViewState extends State<ContactsGroupedView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsProvider>().fetchGroupedContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 🔍 Barre de recherche toujours visible
            ContactsSearchBar(
              controller: _searchController,
              onChanged: provider.filterContacts,
            ),

            Expanded(
              child: Builder(
                builder: (context) {
                  // ⏳ Loading
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
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

                  // 📭 EMPTY STATE (aucun contact chargé)
                  if (provider.groups.isEmpty) {
                    return _stateWidget(
                      context,
                      title: 'Aucun contact',
                      subtitle: 'Scannez une carte ou partagez\nla vôtre pour commencer',
                      showShareButton: true,
                    );
                  }

                  // 🔎 NO MATCH STATE (recherche ne correspond à aucun contact)
                  if (provider.noMatch) {
                    return _stateWidget(
                      context,
                      title: 'Aucun contact ne correspond',
                      subtitle: 'Essayez avec un autre nom, email ou numéro de téléphone',
                      showShareButton: false,
                    );
                  }

                  // ✅ Liste de contacts filtrés
                  return ListView.builder(
                    itemCount: provider.filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = provider.filteredGroups[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              group.highlight.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                          ...group.contacts.map((c) => ContactRow(contact: c)),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stateWidget(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool showShareButton,
  }) {
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône animée
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: companyColor.withValues(alpha:0.05))),
                  Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: companyColor.withValues(alpha:0.1))),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          companyColor.withValues(alpha:0.2),
                          companyColor.withValues(alpha:0.1),
                        ],
                      ),
                    ),
                    child: Icon(Icons.people_outline_rounded, size: 32, color: companyColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.onSurface, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: colors.onSurface.withValues(alpha:0.5), height: 1.4)),
            const SizedBox(height: 32),
            if (showShareButton)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [companyColor, companyColor.withValues(alpha:0.8)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: companyColor.withValues(alpha:0.4), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.share_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Partager ma carte', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

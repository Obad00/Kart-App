import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final Set<int> _selectedContacts = {};
  String? selectedExample;

  final List<String> exampleMessages = [
    "Bonjour, ravi de vous rencontrer !",
    "Salut, merci pour votre temps lors de l'événement.",
    "Bonjour, voici ma carte digitale !",
    "Merci pour l'échange, restons en contact.",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ContactsProvider>().fetchGroupedContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _toggleSelection(int contactId) {
    setState(() {
      if (_selectedContacts.contains(contactId)) {
        _selectedContacts.remove(contactId);
      } else {
        _selectedContacts.add(contactId);
      }
    });
  }

  Future<void> _sendEmails() async {
    if (_selectedContacts.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final content = _emailController.text.trim();
    if (content.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Le message ne peut pas être vide')),
      );
      return;
    }

    try {
      await context.read<ContactsProvider>().sendMessage(
            contactIds: _selectedContacts.toList(),
            content: content,
            type: _selectedContacts.length > 1 ? 'group' : 'single',
          );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Message envoyé avec succès !')),
      );

      _emailController.clear();
      setState(() {
        _selectedContacts.clear();
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

 void _openEmailPopup(String contactEmail) {
  _emailController.text = '';
  final selectedExampleNotifier = ValueNotifier<String?>(null);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Envoyer un email"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _emailController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Écrivez votre message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Exemples de messages",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ✅ Version moderne : Radio + ValueNotifier, plus de groupValue direct
            ...exampleMessages.map((msg) {
              return ValueListenableBuilder<String?>(
                valueListenable: selectedExampleNotifier,
                builder: (context, selected, _) {
                  final isSelected = selected == msg;
                  return ListTile(
                    title: Text(msg),
                    leading: GestureDetector(
                      onTap: () {
                        selectedExampleNotifier.value = msg;
                        _emailController.text = msg;
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    onTap: () {
                      selectedExampleNotifier.value = msg;
                      _emailController.text = msg;
                    },
                  );
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler")),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendEmails();
            },
            child: const Text("Envoyer")),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            ContactsSearchBar(
              controller: _searchController,
              onChanged: provider.filterContacts,
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Text(provider.error!,
                          style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (provider.groups.isEmpty) {
                    return _stateWidget(
                        context,
                        title: 'Aucun contact',
                        subtitle: 'Scannez une carte ou partagez\nla vôtre pour commencer',
                        showShareButton: true);
                  }
                  if (provider.noMatch) {
                    return _stateWidget(
                        context,
                        title: 'Aucun contact ne correspond',
                        subtitle: 'Essayez avec un autre nom, email ou numéro',
                        showShareButton: false);
                  }

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
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5)),
                            ),
                          ),
                          ...group.contacts.map((c) {
                            final isSelected = _selectedContacts.contains(c.id);
                            return ContactRow(
                              contact: c,
                              isSelected: isSelected,
                              onMessageTap: () => _toggleSelection(c.id),
                              onMailTap: () {
                                if (!_selectedContacts.contains(c.id)) {
                                  _toggleSelection(c.id);
                                }
                                _openEmailPopup(c.email ?? '');
                              },
                            );
                          }),
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

  Widget _stateWidget(BuildContext context,
      {required String title, required String subtitle, required bool showShareButton}) {
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: companyColor.withValues(alpha: 0.05),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: companyColor.withValues(alpha: 0.1),
                    ),
                  ),
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
                    child: Icon(Icons.people_outline_rounded,
                        size: 32, color: companyColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(title,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    height: 1.4)),
            const SizedBox(height: 32),
            if (showShareButton)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [companyColor, companyColor.withValues(alpha: 0.8)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: companyColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Partager ma carte',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
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

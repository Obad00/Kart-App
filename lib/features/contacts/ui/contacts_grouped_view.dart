import 'dart:io';

import 'package:csv/csv.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_search_bar.dart';
import '../../navigation/home_shell.dart';
import '../models/contact_model.dart';
import '../providers/contacts_provider.dart';
import '../widgets/contact_row.dart';
import '../widgets/add_contact_sheet.dart';
import '../widgets/favorites_strip.dart';

// Couleur bleue thème
const Color _themeBlue = Color(0xFF3B82F6);

class ContactsGroupedView extends StatefulWidget {
  final ValueChanged<int>? onSelectionChanged;
  final bool selectionModeActive;
  // Pré-arme le mode sélection (0 contact sélectionné pour l'instant) —
  // permet ensuite de sélectionner en tapant n'importe où sur une ligne,
  // pas seulement son cercle dédié.
  final VoidCallback? onEnterSelectionMode;
  // Annule complètement la sélection en cours (vide la liste ET quitte le
  // mode) — utilisé par "Terminer la sélection" et le tap en dehors des
  // contacts.
  final VoidCallback? onCancelSelection;

  const ContactsGroupedView({
    super.key,
    this.onSelectionChanged,
    this.selectionModeActive = false,
    this.onEnterSelectionMode,
    this.onCancelSelection,
  });

  @override
  State<ContactsGroupedView> createState() => ContactsGroupedViewState();
}

class ContactsGroupedViewState extends State<ContactsGroupedView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final Set<int> selectedContacts = {};
  // null = tous highlights confondus.
  int? _highlightFilterId;

  void clearSelection() {
    setState(() {
      selectedContacts.clear();
    });
    widget.onSelectionChanged?.call(0);
  }

  final List<String> exampleMessages = [
    "Ravi de vous rencontrer ! 🤝",
    "Merci pour cet échange enrichissant",
    "Restons en contact 📲",
    "Au plaisir de collaborer ensemble",
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

  Future<void> exportSelectedContacts() async {
    if (selectedContacts.isEmpty) {
      _showSnackBar(
        title: 'Aucun contact sélectionné',
        subtitle: 'Sélectionnez au moins un contact',
        icon: Icons.info_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    _exportContactsAsCSV();
  }

  Future<void> _exportContactsAsCSV() async {
    try {
      final provider = context.read<ContactsProvider>();
      final allContacts = provider.allContacts;
      final selectedContactsList = allContacts
          .where((contact) => selectedContacts.contains(contact.id))
          .toList();

      if (selectedContactsList.isEmpty) {
        _showSnackBar(
          title: 'Erreur',
          subtitle: 'Impossible de trouver les contacts sélectionnés',
          icon: Icons.error_rounded,
          iconColor: Colors.red,
        );
        return;
      }

      // Prepare CSV headers — toutes les infos disponibles sur un contact,
      // pas juste un sous-ensemble.
      final headers = [
        'Nom',
        'Email',
        'Téléphone',
        'Entreprise',
        'Poste',
        'LinkedIn',
        'Twitter',
        'Facebook',
        'Instagram',
        'Site Web',
        'Highlight',
        'Date de rencontre',
        'Favori',
      ];

      // Prepare CSV rows
      final rows = selectedContactsList.map((contact) => [
            contact.fullname,
            contact.email ?? '',
            contact.phone ?? '',
            contact.company ?? '',
            contact.job ?? '',
            contact.linkedin ?? '',
            contact.twitter ?? '',
            contact.facebook ?? '',
            contact.instagram ?? '',
            contact.website ?? '',
            contact.highlightName ?? '',
            contact.capturedAt != null
                ? '${contact.capturedAt!.day.toString().padLeft(2, '0')}/'
                    '${contact.capturedAt!.month.toString().padLeft(2, '0')}/'
                    '${contact.capturedAt!.year}'
                : '',
            contact.isFavorite ? 'Oui' : 'Non',
          ]).toList();

      // Generate CSV
      final csvData =
          const ListToCsvConverter().convert([headers, ...rows]);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'contacts_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(csvData);

      if (!mounted) return;

      // Share file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Mes contacts KART',
        ),
      );

      if (!mounted) return;

      selectedContacts.clear();
      setState(() {});
      widget.onSelectionChanged?.call(0);

      _showSnackBar(
        title: 'Succès',
        subtitle:
            '${selectedContactsList.length} contact(s) exporté(s) en CSV',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ _exportContactsAsCSV Exception: $e');
      _showSnackBar(
        title: 'Erreur d\'export',
        subtitle:
            'Une erreur est survenue lors de l\'export : ${e.toString()}',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _deleteSingleContact(ContactModel contact) async {
    final provider = context.read<ContactsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ce contact ?'),
        content: Text(
          'Voulez-vous vraiment supprimer ${contact.fullname} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.deleteContact(contact.id);
      if (!mounted) return;
      selectedContacts.remove(contact.id);
      widget.onSelectionChanged?.call(selectedContacts.length);
      _showSnackBar(
        title: 'Contact supprimé',
        subtitle: '${contact.fullname} a été supprimé',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ _deleteSingleContact Exception: $e');
      _showSnackBar(
        title: 'Erreur',
        subtitle: 'Une erreur est survenue lors de la suppression',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> deleteSelectedContacts() async {
    if (selectedContacts.isEmpty) {
      _showSnackBar(
        title: 'Aucun contact sélectionné',
        subtitle: 'Sélectionnez au moins un contact',
        icon: Icons.info_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    final count = selectedContacts.length;
    final provider = context.read<ContactsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer les contacts ?'),
        content: Text(
          count > 1
              ? 'Voulez-vous vraiment supprimer ces $count contacts ? Cette action est irréversible.'
              : 'Voulez-vous vraiment supprimer ce contact ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Future.wait(
        selectedContacts.map((id) => provider.deleteContact(id)),
      );

      if (!mounted) return;

      selectedContacts.clear();
      setState(() {});
      widget.onSelectionChanged?.call(0);

      _showSnackBar(
        title: 'Succès',
        subtitle: count > 1
            ? '$count contacts supprimés'
            : 'Contact supprimé',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ deleteSelectedContacts Exception: $e');
      _showSnackBar(
        title: 'Erreur',
        subtitle: 'Une erreur est survenue lors de la suppression',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _shareContact({
    required ContactModel contact,
    required String message,
    required void Function(bool value) setLoading,
  }) async {
    final slug = contact.cardSlug ?? '';

    if (slug.isEmpty) {
      _showSnackBar(
        title: 'Carte introuvable',
        subtitle: 'Ce contact n\'a pas de carte associée.',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
      return;
    }

    setLoading(true);

    try {
      await context.read<ContactsProvider>().shareContact(
            slug: slug,
            message: message.trim().isNotEmpty ? message.trim() : null,
          );

      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      _showSnackBar(
        title: 'Envoyé',
        subtitle: 'Votre carte a été envoyée à ${contact.fullname}',
        icon: Icons.check_circle_rounded,
        iconColor: Colors.green,
      );
    } on DioException catch (e) {
      debugPrint(
          '❌ _shareContact DioException status=${e.response?.statusCode}');
      debugPrint('❌ Response data: ${e.response?.data}');

      String errorMessage = 'Échec de l\'envoi';

      if (e.response?.statusCode == 500) {
        errorMessage = 'Erreur du serveur. Veuillez réessayer plus tard.';
      } else if (e.response?.statusCode == 422) {
        errorMessage =
            'Données invalides. Vérifiez les informations du contact.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Carte introuvable';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'Vous n\'avez pas les permissions nécessaires';
      } else if (e.response?.data is Map) {
        final message = e.response?.data['message'];
        if (message != null) {
          errorMessage = message.toString();
        }
      }

      _showSnackBar(
        title: 'Erreur d\'envoi',
        subtitle: errorMessage,
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    } catch (e) {
      debugPrint('❌ _shareContact Exception: $e');
      _showSnackBar(
        title: 'Erreur',
        subtitle: 'Une erreur inattendue s\'est produite',
        icon: Icons.error_rounded,
        iconColor: Colors.red,
      );
    } finally {
      if (mounted) setLoading(false);
    }
  }

  void _showSnackBar({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  void _openShareContactPopup(ContactModel contact) {
    final messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Relancer le contact',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Renvoyer votre carte',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Contact Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              Icons.person_rounded, 'Nom', contact.fullname),
                          if (contact.email != null &&
                              contact.email!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                                Icons.email_rounded, 'Email', contact.email!),
                          ],
                          if (contact.phone != null &&
                              contact.phone!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.phone_rounded, 'Téléphone',
                                contact.phone!),
                          ],
                          if (contact.company != null &&
                              contact.company!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.business_rounded, 'Entreprise',
                                contact.company!),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Optional message
                    Text(
                      "Message personnalisé (optionnel)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: messageController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: "Ajoutez un message personnel...",
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    await _shareContact(
                                      contact: contact,
                                      message: messageController.text.trim(),
                                      setLoading: (value) => setDialogState(
                                          () => isLoading = value),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Envoyer',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _themeBlue.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const companyColor = _themeBlue;

    return Consumer<ContactsProvider>(
      builder: (context, provider, _) {
        final colors = Theme.of(context).colorScheme;

        return Column(
          children: [
            // En-tête : titre + total de contacts / favoris + actions (+ / ...)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contacts',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface.withValues(alpha: 0.55),
                            ),
                            children: [
                              TextSpan(text: '${provider.allContacts.length} contacts · '),
                              TextSpan(
                                text:
                                    '${provider.groups.where((g) => g.highlight.id != 0).length} highlights',
                                style: const TextStyle(
                                  color: _themeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SquareIconButton(
                    icon: Icons.person_add_alt_1_rounded,
                    tooltip: 'Ajouter un contact',
                    onTap: () => showAddContactSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _ContactsMenuButton(
                    // Basé sur la sélection RÉELLE (selectedContacts), pas
                    // sur le flag externe — sinon "Supprimer"/"Exporter" ne
                    // faisaient rien la première fois qu'on les cliquait
                    // quand la sélection avait démarré via le cercle d'une
                    // ligne plutôt que via ce menu.
                    selectionModeActive: selectedContacts.isNotEmpty,
                    onSelect: () {
                      if (selectedContacts.isNotEmpty) {
                        clearSelection();
                        widget.onCancelSelection?.call();
                      } else {
                        widget.onEnterSelectionMode?.call();
                      }
                    },
                    onExport: () {
                      if (selectedContacts.isEmpty) {
                        widget.onEnterSelectionMode?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Sélectionnez les contacts à exporter, puis validez en bas.'),
                          ),
                        );
                      } else {
                        exportSelectedContacts();
                      }
                    },
                    onDelete: () {
                      if (selectedContacts.isEmpty) {
                        widget.onEnterSelectionMode?.call();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Sélectionnez les contacts à supprimer, puis validez en bas.'),
                          ),
                        );
                      } else {
                        deleteSelectedContacts();
                      }
                    },
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: AppSearchBar(
                controller: _searchController,
                hintText: 'Rechercher un contact...',
                accentColor: companyColor,
                onChanged: (value) {
                  provider.filterContacts(value);
                  setState(() {});
                },
              ),
            ),

            // Filtre par highlight — plusieurs événements peuvent se
            // mélanger dans "Tous", pratique pour isoler par ex. seulement
            // les contacts du "Dakar Business Forum".
            _buildHighlightFilterRow(provider),

            // Favoris — accès rapide façon "à la une"
            FavoritesStrip(
              favorites: provider.favoriteContacts,
              onTapFavorite: (contact) {
                HapticFeedback.lightImpact();
                _openShareContactPopup(contact);
              },
            ),

            // Content
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (selectedContacts.isNotEmpty) {
                    clearSelection();
                    widget.onCancelSelection?.call();
                  }
                },
                child: Builder(
                builder: (context) {
                  if (provider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(companyColor),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chargement des contacts...',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchGroupedContacts(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: companyColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.groups.isEmpty) {
                    return _emptyState(context, companyColor);
                  }

                  if (provider.noMatch) {
                    return _noMatchState(context);
                  }

                  // Liste plate de lignes (avatar, nom, poste, badge
                  // highlight + date), triée par date d'ajout la plus
                  // récente — les sections par highlight ont été
                  // abandonnées au profit de ce badge par ligne, plus
                  // lisible, et filtrable via les chips au-dessus.
                  final contacts = provider.allContacts
                      .where((c) => provider.matchesQuery(c))
                      .where((c) =>
                          _highlightFilterId == null ||
                          c.highlightId == _highlightFilterId)
                      .toList()
                    ..sort((a, b) {
                      if (a.capturedAt == null && b.capturedAt == null) return 0;
                      if (a.capturedAt == null) return 1;
                      if (b.capturedAt == null) return -1;
                      return b.capturedAt!.compareTo(a.capturedAt!);
                    });

                  return _buildFlatList(context, contacts);
                },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Liste plate de lignes (recherche / filtre highlight) — remplace
  /// l'ancienne grille groupée par sections de highlight.
  Widget _buildFlatList(BuildContext context, List<ContactModel> contacts) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'Aucun contact',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: contacts.length,
      itemBuilder: (context, index) => _buildContactRow(contacts[index]),
    );
  }

  Widget _buildContactRow(ContactModel c) {
    return ContactRow(
      contact: c,
      isSelected: selectedContacts.contains(c.id),
      selectionModeActive: widget.selectionModeActive,
      onSelect: (id) {
        setState(() {
          if (selectedContacts.contains(id)) {
            selectedContacts.remove(id);
          } else {
            selectedContacts.add(id);
          }
        });
        widget.onSelectionChanged?.call(selectedContacts.length);
      },
      onToggleFavorite: () => context.read<ContactsProvider>().toggleFavorite(c.id),
      onDelete: () => _deleteSingleContact(c),
    );
  }

  /// Rangée de chips pour filtrer la liste par highlight (événement) —
  /// masquée s'il n'y a aucun highlight utilisé sur ces contacts.
  Widget _buildHighlightFilterRow(ContactsProvider provider) {
    final highlights = provider.groups
        .map((g) => g.highlight)
        .where((h) => h.id != 0)
        .toList();

    if (highlights.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        scrollDirection: Axis.horizontal,
        itemCount: highlights.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final active = _highlightFilterId == null;
            return ChoiceChip(
              label: const Text('Tous highlights'),
              selected: active,
              onSelected: (_) => setState(() => _highlightFilterId = null),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
              ),
              selectedColor: _themeBlue,
              backgroundColor: colors.onSurface.withValues(alpha: 0.06),
              side: BorderSide.none,
            );
          }

          final highlight = highlights[index - 1];
          final active = _highlightFilterId == highlight.id;
          return ChoiceChip(
            label: Text(highlight.name),
            selected: active,
            onSelected: (_) => setState(() =>
                _highlightFilterId = active ? null : highlight.id),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.7),
            ),
            selectedColor: _themeBlue,
            backgroundColor: colors.onSurface.withValues(alpha: 0.06),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context, Color companyColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      companyColor.withValues(alpha: 0.15),
                      companyColor.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.people_outline_rounded,
                  size: 64,
                  color: companyColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun contact',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scannez une carte ou partagez\nla vôtre pour commencer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const HomeShell(initialIndex: 0),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: companyColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Partager ma carte',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noMatchState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun résultat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez avec un autre nom,\nemail ou numéro de téléphone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton carré à côté de la barre de recherche (Sélectionner / Ajouter).
class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _themeBlue, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: _themeBlue,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton "..." → menu Exporter / Sélectionner / Supprimer, en haut à côté
/// du titre (façon menu contextuel Apple).
class _ContactsMenuButton extends StatelessWidget {
  final bool selectionModeActive;
  final VoidCallback onSelect;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _ContactsMenuButton({
    required this.selectionModeActive,
    required this.onSelect,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'Plus d\'options',
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        HapticFeedback.lightImpact();
        switch (value) {
          case 'export':
            onExport();
            break;
          case 'select':
            onSelect();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_upload_outlined, color: _themeBlue, size: 20),
              SizedBox(width: 12),
              Text('Exporter (.CSV)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'select',
          child: Row(
            children: [
              Icon(
                selectionModeActive
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                color: _themeBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(selectionModeActive ? 'Terminer la sélection' : 'Sélectionner'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: colors.onSurface.withValues(alpha: 0.7),
          size: 20,
        ),
      ),
    );
  }
}


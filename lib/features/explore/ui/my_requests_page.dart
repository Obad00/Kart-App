import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/connection_request_item.dart';
import '../providers/explore_provider.dart';
import '../../public_card/ui/public_card_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/sticky_header_delegate.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';

const _themeBlue = Color(0xFF3B82F6);

/// "Mes demandes" — accepter/refuser une demande de connexion reçue,
/// suivre celles envoyées. Anciennement un onglet de la page Explorer
/// (pilule "Découvrir"/"Mes demandes"), désormais un écran à part entière
/// ouvert depuis le bouton filtre d'Explorer — le nouveau design de cette
/// page n'a plus de place pour un onglet visible en permanence.
///
/// Attend un [ExploreProvider] déjà fourni par un ancêtre (même instance
/// que celle d'Explorer, passée via `ChangeNotifierProvider.value` au
/// moment du push) — pas de service/chargement propre ici.
class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  static const double _statusChipsRowHeight = 40;

  @override
  void initState() {
    super.initState();
    // Différé (postFrameCallback) plutôt qu'appelé directement ici : cette
    // page partage la même instance d'ExploreProvider qu'ExplorePage
    // (toujours montée dessous, pas remplacée), donc son
    // notifyListeners() synchrone atteindrait aussi les Consumer
    // d'ExplorePage — en plein milieu du build de la transition de push
    // vers cet écran, ce qui déclenche l'assertion Flutter
    // "!_dirty is not true" (setState pendant un build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ExploreProvider>();
      if (provider.myRequests.isEmpty) {
        provider.loadMyRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(
      title: const Text('Mes demandes'),
    );
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    // Pas de Scaffold : poussée par-dessus HomeShell (qui possède déjà le
    // sien) via Navigator.push classique — même principe que PublicCardPage.
    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    height: topPadding + 12 + _statusChipsRowHeight + 4,
                    blurBackground: true,
                    child: Column(
                      children: [
                        SizedBox(height: topPadding),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              _StatusChip(label: 'Toutes', status: 'all'),
                              const SizedBox(width: 8),
                              _StatusChip(
                                  label: 'En attente', status: 'pending'),
                              const SizedBox(width: 8),
                              _StatusChip(
                                  label: 'Acceptées', status: 'accepted'),
                              const SizedBox(width: 8),
                              _StatusChip(
                                  label: 'Refusées', status: 'declined'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Consumer<ExploreProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoadingMyRequests) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (provider.myRequests.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Aucune demande pour l\'instant',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: 24 +
                            BottomNavMetrics.bottomInset(
                                MediaQuery.of(context).padding.bottom),
                      ),
                      sliver: SliverList.builder(
                        itemCount: provider.myRequests.length,
                        itemBuilder: (context, index) =>
                            _MyRequestRow(item: provider.myRequests[index]),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: topPadding, child: glassAppBar),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String status;

  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final active = provider.myRequestsStatusFilter == status;
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        context.read<ExploreProvider>().loadMyRequests(status: status);
      },
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
}

class _MyRequestRow extends StatelessWidget {
  final ConnectionRequestItem item;

  const _MyRequestRow({required this.item});

  Color _statusColor() {
    switch (item.status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case 'accepted':
        return 'Acceptée';
      case 'declined':
        return 'Refusée';
      default:
        return 'En attente';
    }
  }

  /// Sans afficher l'erreur retournée par le provider, un échec réseau/
  /// serveur sur Accepter/Refuser ne montrait strictement rien à
  /// l'utilisateur — d'où l'impression que "rien ne se passe".
  Future<void> _respond(BuildContext context, String action) async {
    final error = await context
        .read<ExploreProvider>()
        .respondFromMyRequests(item.id, action);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = item.otherUser;
    final isPendingReceived =
        item.status == 'pending' && item.direction == RequestDirection.received;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              item.direction == RequestDirection.sent
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              // La ligne entière ouvre la carte de la personne — pour une
              // demande reçue, on veut pouvoir juger qui c'est avant
              // d'accepter/refuser, pas seulement lire un nom.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final slug = user.cardSlug;
                  if (slug == null || slug.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicCardPage(slug: slug)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((user.jobTitle ?? user.company ?? '').isNotEmpty)
                      Text(
                        [user.jobTitle, user.company]
                            .where((v) => (v ?? '').isNotEmpty)
                            .join(' · '),
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.55)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            if (isPendingReceived)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleActionButton(
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    onTap: () => _respond(context, 'decline'),
                  ),
                  const SizedBox(width: 8),
                  _CircleActionButton(
                    icon: Icons.check_rounded,
                    color: Colors.green,
                    onTap: () => _respond(context, 'accept'),
                  ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Petit bouton rond (✓/✕) pour accepter/refuser une demande reçue
/// directement dans la liste, sans passer par le mail.
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

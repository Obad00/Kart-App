import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/connection_request_item.dart';
import '../models/explore_user.dart' show ConnectionStatus;
import '../providers/connection_badge_provider.dart';
import '../providers/explore_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../public_card/ui/public_card_page.dart';
import '../../../shared/widgets/app_loader.dart';
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
  // 44 (pas 40), même hauteur que les puces de catégorie d'Explorer
  // (_chipsRowHeight) — marge de sécurité pour le texte d'une puce
  // (padding interne 10+10, cf. _StatusChip), plutôt qu'une valeur qui se
  // révèle tout juste suffisante en pratique.
  static const double _statusChipsRowHeight = 44;

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
                        SizedBox(height: topPadding + 12),
                        // ListView horizontal (pas un Row figé) : sur un
                        // écran étroit, les 4 puces dépassaient la largeur
                        // disponible et "Refusées" se retrouvait coupée à
                        // droite — remonté côté produit. Même motif que les
                        // puces de catégorie d'Explorer (_buildCategoryChips).
                        //
                        // padding horizontal SEULEMENT (pas vertical) : ce
                        // ListView est déjà strictement borné à
                        // _statusChipsRowHeight par le SizedBox ci-dessous —
                        // lui ajouter EN PLUS un padding vertical (12+4=16)
                        // ne laissait quasiment plus de place aux puces
                        // elles-mêmes (padding interne 10+10) pour leur
                        // propre texte, qui se retrouvait rogné à
                        // l'invisible — remonté côté produit avec capture
                        // à l'appui ("je ne vois plus le contenu des puces").
                        SizedBox(
                          height: _statusChipsRowHeight,
                          child: ListView(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
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
                        child: AppLoader(label: 'Chargement de vos demandes...'),
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

// Container/Material personnalisé, plus le ChoiceChip Material d'origine
// — remonté côté produit ("le contenu est collé/coupé en dessous dans
// chaque puce") : ChoiceChip applique son propre padding vertical interne
// (asymétrique une fois combiné à sa coche de sélection), différent de
// celui des autres puces de l'app (cf. _CategoryChip dans explore_page.dart,
// dont ce widget reprend maintenant exactement le patron : Material +
// InkWell + Padding symétrique 14/10, sans coche).
class _StatusChip extends StatelessWidget {
  final String label;
  final String status;

  const _StatusChip({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final active = provider.myRequestsStatusFilter == status;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: active ? _themeBlue : colors.onSurface.withValues(alpha: 0.06),
      // Même contour que le bouton "Se connecter" et que les puces
      // d'Explorer (cf. _CategoryChip) — homogénéité demandée côté produit.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: _themeBlue.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.selectionClick();
          context.read<ExploreProvider>().loadMyRequests(status: status);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
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
    if (error != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (action == 'accept') {
      // ContactsProvider est un singleton chargé une seule fois au
      // démarrage de l'app — sans ce refresh explicite, accepter une
      // demande ici n'affichait le nouveau contact dans l'onglet Contacts
      // qu'après avoir quitté et relancé l'app.
      context.read<ContactsProvider>().fetchGroupedContacts();
    }
    // Accepter ou refuser résout une demande reçue en attente : le badge
    // de la barre de nav doit le refléter tout de suite.
    context.read<ConnectionBadgeProvider>().refresh();
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
                      builder: (_) => PublicCardPage(
                        slug: slug,
                        // Une demande encore en attente doit rester
                        // "Accepter/Refuser" une fois le profil ouvert, pas
                        // redevenir "Se connecter" (cf. PublicCardPage).
                        initialConnectionStatus: item.status != 'pending'
                            ? null
                            : (item.direction == RequestDirection.received
                                ? ConnectionStatus.pendingReceived
                                : ConnectionStatus.pendingSent),
                        initialConnectionRequestId:
                            item.status == 'pending' ? item.id : null,
                      ),
                    ),
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

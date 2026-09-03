import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../models/connection_request_item.dart';
import '../models/explore_user.dart';
import '../providers/community_provider.dart';
import '../providers/connection_badge_provider.dart';
import '../providers/explore_provider.dart';
import '../services/community_service.dart';
import '../services/explore_service.dart';
import '../widgets/community_card.dart';
import '../widgets/connect_action_button.dart';
import 'communities_page.dart';
import '../../public_card/ui/public_card_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/sticky_header_delegate.dart';

const _themeBlue = Color(0xFF3B82F6);

/// "Explorer" — annuaire des utilisateurs KART avec une carte publique
/// active. Envoyer une demande de mise en relation notifie l'autre
/// personne par mail (avec des liens Accepter/Refuser, sans connexion
/// requise) ; si elle accepte, un contact se crée automatiquement des deux
/// côtés. L'onglet "Mes demandes" permet aussi de répondre directement
/// dans l'app.
class ExplorePage extends StatefulWidget {
  // 1 = ouvre directement "Mes demandes" — utilisé par le mail de demande
  // de connexion et par le tap sur la notification push correspondante.
  final int initialTabIndex;

  const ExplorePage({super.key, this.initialTabIndex = 0});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late final ExploreProvider _provider;
  late final CommunityProvider _communityProvider;
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _provider = ExploreProvider(ExploreService());
    _communityProvider = CommunityProvider(CommunityService());
    _communityProvider.loadCommunities();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    if (widget.initialTabIndex == 1) {
      _provider.loadMyRequests();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ConnectionBadgeProvider>().clearBadge(),
      );
    }
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        if (_provider.myRequests.isEmpty) {
          _provider.loadMyRequests();
        }
        // Le badge (même compteur que celui de la barre de nav) ne
        // s'efface qu'ici, à l'ouverture réelle de "Mes demandes" — pas
        // dès qu'on arrive sur Explorer, sinon il aurait déjà disparu
        // avant même que cet onglet ait pu l'afficher à son tour.
        context.read<ConnectionBadgeProvider>().clearBadge();
      }
    });
    _provider.loadUsers();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _provider.loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _provider.loadUsers(search: value.trim());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    _provider.dispose();
    _communityProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Même compteur que le badge de la barre de navigation (voir
    // home_shell.dart) — affiché ici aussi, sur l'onglet "Mes demandes",
    // pour signaler une demande non traitée avant même de l'avoir ouvert.
    final pendingCount =
        context.watch<ConnectionBadgeProvider>().pendingReceivedCount;

    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(
      title: const Text('Explorer'),
      // Pilule "segmented control" (fintech/travel) plutôt que le simple
      // soulignement Material par défaut — plus proche des captures de
      // référence pour cette page.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _themeBlue,
                borderRadius: BorderRadius.circular(999),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(999),
              labelColor: Colors.white,
              unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                const Tab(text: 'Découvrir'),
                Tab(
                    child: _TabLabelWithBadge(
                        label: 'Mes demandes', count: pendingCount)),
              ],
            ),
          ),
        ),
      ),
    );

    // Hauteur totale de la barre (statut + toolbar + TabBar) : passée aux
    // onglets pour qu'ils réservent la place en haut de LEUR scrollable —
    // pas via un spacer externe, sinon rien ne défile jamais derrière la
    // barre et le flou n'a rien à flouter (elle paraît alors juste comme un
    // fond uni classique, cf. capture d'écran).
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    // Pas de Scaffold ici : HomeShell en possède déjà un pour toute la
    // navigation (fond colorScheme.surface unique, cf. AppTheme). GlassAppBar
    // n'a besoin que d'un AppBar (widget autonome, pas de dépendance à
    // Scaffold) — posé par-dessus le contenu via Positioned pour reproduire
    // l'effet extendBodyBehindAppBar : le contenu défile réellement dessous,
    // chaque onglet réservant déjà la place nécessaire via topPadding.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _provider),
        ChangeNotifierProvider.value(value: _communityProvider),
      ],
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(topPadding),
                _buildMyRequestsTab(topPadding),
              ],
            ),
          ),
          // SizedBox(height: topPadding) est indispensable : sans lui, ce
          // Positioned (top/left/right seuls, pas de bottom) donne à
          // GlassAppBar une hauteur non contrainte, et l'AppBar interne (qui
          // empile toolbar + TabBar dans une Column avec Expanded) plante en
          // layout — c'est exactement ce que fait Scaffold(appBar: ...) en
          // interne pour n'importe quel AppBar, et qu'il faut donc refaire à
          // la main ici. topPadding (pas juste preferredSize.height) car
          // l'AppBar réserve lui-même la place de la status bar en plus de
          // sa propre hauteur quand primary vaut true (par défaut).
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

  // AppSearchBar n'a pas de hauteur fixe (elle dépend du TextField interne
  // — icône de suffixe "effacer" quand une recherche est tapée, réglages
  // d'accessibilité...) : 58 était trop juste et provoquait "A RenderFlex
  // overflowed by 5.0 pixels" dans l'en-tête épinglé dès que le champ
  // dépassait ne serait-ce que de quelques pixels. Marge de sécurité +6.
  static const double _searchBarHeight = 64;
  static const double _filterRowHeight = 44;

  Widget _buildDiscoverTab(double topPadding) {
    // top:false : le haut est déjà géré manuellement via topPadding (pour
    // laisser le contenu défiler sous la barre verre dépoli) — seul le bas
    // (zone de geste/home indicator) doit encore être protégé ici.
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(child: _buildDiscoverScrollable(topPadding)),
          // "Réseaux populaires" — fixe en bas de la page (comme le TabBar
          // en haut), visible dès l'arrivée sur Explorer ; les profils à
          // connecter défilent en dessous de la recherche, au-dessus de ce
          // bloc qui lui ne bouge pas. Le carrousel lui-même reste un
          // scroll horizontal indépendant (cf. _CommunitiesSection).
          _buildCommunitiesFooter(),
        ],
      ),
    );
  }

  Widget _buildCommunitiesFooter() {
    final colors = Theme.of(context).colorScheme;

    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        // Rien à afficher (pas même la bordure) tant qu'aucune communauté
        // n'a été créée par le superadmin, ou en cas d'échec réseau.
        if (!provider.isLoading && provider.communities.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              top: BorderSide(color: colors.onSurface.withValues(alpha: 0.06)),
            ),
          ),
          child: Padding(
            // Juste la place de la pilule de nav flottante de HomeShell
            // (extendBody, sinon elle cacherait le bas du carrousel) — pas
            // de marge supplémentaire au-delà, pour rester collé à elle.
            padding: const EdgeInsets.only(
              top: 4,
              bottom: BottomNavMetrics.reservedHeight,
            ),
            child: const _CommunitiesSection(),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverScrollable(double topPadding) {
    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // SliverPersistentHeader(pinned:true) plutôt que SliverToBoxAdapter :
        // recherche + filtres restent fixes en haut pendant qu'on scrolle la
        // liste, au lieu de défiler avec elle.
        Consumer<ExploreProvider>(
          builder: (context, provider, _) {
            final hasFilters = provider.jobTitles.isNotEmpty;
            final height = topPadding +
                12 +
                _searchBarHeight +
                8 +
                (hasFilters ? _filterRowHeight : 0);

            return SliverPersistentHeader(
              pinned: true,
              delegate: StickyHeaderDelegate(
                height: height,
                blurBackground: true,
                child: Column(
                  children: [
                    SizedBox(height: topPadding),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: AppSearchBar(
                        controller: _searchController,
                        hintText: 'Rechercher par nom, poste, entreprise...',
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (hasFilters) _buildJobTitleFilterRow(provider),
                  ],
                ),
              ),
            );
          },
        ),
        Consumer<ExploreProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (provider.error != null) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(provider.error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.loadUsers(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (provider.users.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _themeBlue.withValues(alpha: 0.12),
                                const Color(0xFF6D28D9).withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.explore_outlined,
                              size: 40, color: _themeBlue),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Aucun profil à découvrir pour le moment',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SliverList.builder(
              itemCount: provider.users.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.users.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ExploreUserRow(user: provider.users[index]);
              },
            );
          },
        ),
        // Simple respiration avant le bloc fixe "Réseaux populaires" —
        // qui, lui, n'est plus dans ce scrollable (cf. _buildDiscoverTab).
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  /// Chips de filtre par poste — même design que le filtre par highlight
  /// dans Contacts, pour repérer plus vite un profil précis.
  Widget _buildJobTitleFilterRow(ExploreProvider provider) {
    if (provider.jobTitles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        itemCount: provider.jobTitles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final active = provider.jobTitleFilter.isEmpty;
            return _FilterChip(
              label: 'Tous postes',
              active: active,
              onTap: () => provider.setJobTitleFilter(''),
            );
          }

          final jobTitle = provider.jobTitles[index - 1];
          final active = provider.jobTitleFilter == jobTitle;
          return _FilterChip(
            label: jobTitle,
            active: active,
            onTap: () => provider.setJobTitleFilter(active ? '' : jobTitle),
          );
        },
      ),
    );
  }

  static const double _statusChipsRowHeight = 40;

  Widget _buildMyRequestsTab(double topPadding) {
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          // Même principe que l'onglet Découvrir : les filtres de statut
          // restent fixes en haut pendant qu'on scrolle la liste.
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
                        _StatusChip(
                          label: 'Toutes',
                          status: 'all',
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: 'En attente', status: 'pending'),
                        const SizedBox(width: 8),
                        _StatusChip(label: 'Acceptées', status: 'accepted'),
                        const SizedBox(width: 8),
                        _StatusChip(label: 'Refusées', status: 'declined'),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 24 + BottomNavMetrics.reservedHeight,
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
    );
  }
}

/// Libellé d'onglet + badge rond rouge — même principe visuel que le badge
/// de "Explorer" dans la barre de navigation (voir home_shell.dart), pour
/// signaler ici une demande de connexion reçue pas encore traitée.
class _TabLabelWithBadge extends StatelessWidget {
  final String label;
  final int count;

  const _TabLabelWithBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(3),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration:
                const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
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

class _ExploreUserRow extends StatelessWidget {
  final ExploreUser user;

  const _ExploreUserRow({required this.user});

  String? get _avatarUrl {
    final avatar = user.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar.startsWith('http')
        ? avatar
        : '${ApiEndpoints.storageUrl}/$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  void _openCard(BuildContext context) {
    final slug = user.cardSlug;
    if (slug == null || slug.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicCardPage(slug: slug)),
    );
  }

  /// Dégradé de marque + initiales géantes en filigrane — utilisé à la fois
  /// pour un profil sans avatar, pendant le chargement de l'avatar, et en
  /// cas d'échec (image cassée/corrompue) : un seul et même repli visuel.
  Widget _avatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(user.name),
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _avatarUrl;
    final jobTitle = user.jobTitle ?? '';
    final company = user.company ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _openCard(context),
          child: Container(
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              // Ombre discrète — juste de quoi détacher la carte du fond,
              // sans l'effet "flottant" trop appuyé d'avant.
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo de profil en fond — ou, à défaut, un dégradé de
                // marque avec les initiales géantes en filigrane, pour
                // garder le même effet "carte photo" plein cadre.
                if (avatarUrl != null)
                  CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    // topCenter plutôt que le center par défaut : sur une
                    // carte plus large que haute, un recadrage centré coupe
                    // fréquemment le haut du visage sur une photo portrait
                    // (le sujet est presque toujours dans le tiers haut de
                    // la photo) — aligner en haut garde la tête visible et
                    // rogne plutôt le bas (épaules/torse).
                    alignment: Alignment.topCenter,
                    // FilterQuality.low (le défaut) rendait les photos assez
                    // agrandies (portrait → carte large plein cadre)
                    // visiblement floues/pixelisées — high lisse ce
                    // redimensionnement.
                    filterQuality: FilterQuality.high,
                    fadeInDuration: const Duration(milliseconds: 200),
                    // Le même dégradé + initiales pendant le chargement,
                    // plutôt qu'un vide qui laisse place à l'image d'un coup
                    // — évite l'effet de "flash" et sert aussi de repli en
                    // cas d'échec (errorWidget).
                    placeholder: (context, url) => _avatarFallback(),
                    errorWidget: (context, url, error) => _avatarFallback(),
                  )
                else
                  _avatarFallback(),

                // Voile dégradé pour la lisibilité du texte en bas de carte
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.4, 1.0],
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),

                // "Profil complet" — met en avant les profils les plus
                // soignés (le backend trie déjà l'annuaire dans cet ordre,
                // ce badge le rend visible sur la carte elle-même).
                if (user.hasCompleteProfile)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 13, color: Color(0xFF34D399)),
                          SizedBox(width: 4),
                          Text(
                            'Profil complet',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Contenu texte + action — épuré : plus de bordures sur les
                // badges, tailles réduites pour une carte plus compacte.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (company.isNotEmpty)
                        Text(
                          company.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox.shrink(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (jobTitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ConnectActionButton(
                                  userId: user.id,
                                  userName: user.name,
                                  initialStatus: user.connectionStatus,
                                  initialRequestId: user.connectionRequestId,
                                  onResolved: () => context
                                      .read<ExploreProvider>()
                                      .removeUserLocally(user.id),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Le tap sur toute la ligne ouvre déjà la carte,
                              // mais ce n'était pas découvrable — un libellé
                              // explicite à côté du bouton de connexion.
                              GestureDetector(
                                onTap: () => _openCard(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Voir la carte',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Réseaux populaires" — carrousel horizontal de communautés (cf. maquette),
/// juste au-dessus de la liste des profils à découvrir. Superadmin only pour
/// la gestion des communautés elles-mêmes (CRM web) ; ici on ne fait que
/// lister/rejoindre.
class _CommunitiesSection extends StatelessWidget {
  const _CommunitiesSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final colors = Theme.of(context).colorScheme;

    // Rien à afficher tant qu'aucune communauté n'a été créée par le
    // superadmin, ou en cas d'échec réseau — pas d'état d'erreur bruyant
    // pour une section secondaire de la page.
    if (!provider.isLoading && provider.communities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Réseaux populaires',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                if (provider.communities.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: const CommunitiesPage(),
                              )),
                    ),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _themeBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (provider.isLoading)
            const SizedBox(
              height: 210,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: provider.communities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final community = provider.communities[index];
                  return SizedBox(
                    width: 220,
                    child: CommunityCard(
                      community: community,
                      onToggleJoin: () => provider.toggleJoin(community),
                    ),
                  );
                },
              ),
            ),
        ],
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../providers/community_provider.dart';
import '../providers/connection_badge_provider.dart';
import '../providers/explore_provider.dart';
import '../services/community_service.dart';
import '../services/explore_service.dart';
import '../widgets/community_card.dart';
import '../widgets/explore_user_row.dart';
import 'all_profiles_page.dart';
import 'communities_page.dart';
import 'my_requests_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/sticky_header_delegate.dart';

const _themeBlue = Color(0xFF3B82F6);

/// "Explorer" — annuaire des utilisateurs KART avec une carte publique
/// active. Envoyer une demande de mise en relation notifie l'autre
/// personne par mail (avec des liens Accepter/Refuser, sans connexion
/// requise) ; si elle accepte, un contact se crée automatiquement des deux
/// côtés. "Mes demandes" (accepter/refuser directement dans l'app) est un
/// écran séparé (cf. MyRequestsPage), ouvert depuis le bouton filtre — la
/// maquette de cette page n'a plus de pilule d'onglets visible en
/// permanence pour ça.
class ExplorePage extends StatefulWidget {
  // 1 = ouvre directement "Mes demandes" — utilisé par le mail de demande
  // de connexion et par le tap sur la notification push correspondante.
  final int initialTabIndex;

  const ExplorePage({super.key, this.initialTabIndex = 0});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final ExploreProvider _provider;
  late final CommunityProvider _communityProvider;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  // Puce de catégorie active dans la rangée sous la recherche — "Pour
  // vous" et "Fonctions" changent réellement la liste (cf. leurs onTap
  // dans _buildCategoryChips) ; "Compétences" et "Réseaux" restent pour
  // l'instant purement visuelles : aucun filtre par compétence ou par
  // réseau n'existe côté backend, elles ne font donc que se marquer
  // sélectionnées, sans rien changer à la liste affichée.
  String _activeChip = 'pour_vous';

  @override
  void initState() {
    super.initState();
    _provider = ExploreProvider(ExploreService());
    _communityProvider = CommunityProvider(CommunityService());
    _communityProvider.loadCommunities();
    _provider.loadUsers();

    if (widget.initialTabIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openMyRequests());
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
    _provider.dispose();
    _communityProvider.dispose();
    super.dispose();
  }

  /// Ouvre "Mes demandes" — même instance d'[ExploreProvider] (état des
  /// demandes, filtre de statut déjà chargé) partagée avec cet écran via
  /// `ChangeNotifierProvider.value`, plutôt qu'un onglet interne. Le badge
  /// (même compteur que la barre de nav) ne s'efface qu'ici, à l'ouverture
  /// réelle — pas dès l'arrivée sur Explorer, sinon il aurait déjà disparu
  /// avant même d'avoir pu s'afficher.
  void _openMyRequests() {
    context.read<ConnectionBadgeProvider>().clearBadge();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _provider,
          child: const MyRequestsPage(),
        ),
      ),
    );
  }

  /// Ouvre la liste complète des profils ("Voir tout" de "Profils suggérés
  /// pour vous", qui n'en montre que les 5 premiers) — même instance
  /// d'[ExploreProvider] partagée, déjà chargée.
  void _openAllProfiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _provider,
          child: const AllProfilesPage(),
        ),
      ),
    );
  }

  /// Bottom sheet ouverte par le bouton rond à côté de la recherche —
  /// donne accès à "Mes demandes", qui n'a plus de pilule d'onglets
  /// visible en permanence dans ce design.
  void _openFiltersSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final colors = Theme.of(context).colorScheme;
    final badgeCount =
        context.read<ConnectionBadgeProvider>().pendingReceivedCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openMyRequests();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _themeBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.inbox_outlined, color: _themeBlue),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mes demandes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Accepter ou refuser une mise en relation',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (badgeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          constraints:
                              const BoxConstraints(minWidth: 22, minHeight: 22),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(Icons.chevron_right_rounded,
                            color: colors.onSurface.withValues(alpha: 0.3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélection de poste (chips) en bottom sheet — déclenchée par la puce
  /// "Fonctions". Reprend le même contenu que l'ancienne rangée de chips
  /// toujours visible, désormais dans une sheet pour laisser la place à
  /// la nouvelle rangée de catégories.
  void _openJobTitleFilter(BuildContext context) {
    if (_provider.jobTitles.isEmpty) return;
    HapticFeedback.lightImpact();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: _provider,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Filtrer par poste',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface),
                ),
                const SizedBox(height: 16),
                Consumer<ExploreProvider>(
                  builder: (context, p, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'Tous postes',
                        active: p.jobTitleFilter.isEmpty,
                        onTap: () {
                          p.setJobTitleFilter('');
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      ...p.jobTitles.map((jobTitle) {
                        final active = p.jobTitleFilter == jobTitle;
                        return _FilterChip(
                          label: jobTitle,
                          active: active,
                          onTap: () {
                            p.setJobTitleFilter(active ? '' : jobTitle);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(
      centerTitle: false,
      title: Text(
        'Explorer',
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: colors.onSurface,
        ),
      ),
    );

    // Hauteur totale de la barre (statut + toolbar) — passée à la liste
    // pour qu'elle réserve la place en haut de SON scrollable, pas via un
    // spacer externe, sinon rien ne défile jamais derrière la barre et le
    // flou n'a rien à flouter.
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    // Pas de Scaffold ici : HomeShell en possède déjà un pour toute la
    // navigation. GlassAppBar posé par-dessus le contenu via Positioned
    // pour reproduire l'effet extendBodyBehindAppBar (le contenu défile
    // réellement dessous).
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
            // top:false ET bottom:false — le bas est géré à la main
            // (BottomNavMetrics dans le spacer de fin de liste), pas via
            // SafeArea(bottom:true) : sinon cette page perd ~34px de
            // hauteur réelle en bas, sur lesquels plus rien ne défile
            // derrière la pilule flottante de HomeShell (extendBody), qui
            // n'y trouve alors qu'un fond uni à flouter au lieu du contenu
            // — contrairement aux autres pages (Profil, Contacts...).
            child: SafeArea(
              top: false,
              bottom: false,
              child: _buildScrollable(topPadding),
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

  // AppSearchBar n'a pas de hauteur fixe (elle dépend du TextField interne)
  // : 58 était trop juste et provoquait un débordement dans l'en-tête
  // épinglé dès que le champ dépassait de quelques pixels. Marge +6.
  static const double _searchBarHeight = 64;
  static const double _chipsRowHeight = 44;

  Widget _buildScrollable(double topPadding) {
    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // SliverPersistentHeader(pinned:true) plutôt que SliverToBoxAdapter :
        // recherche + catégories restent fixes en haut pendant qu'on
        // scrolle la liste, au lieu de défiler avec elle.
        SliverPersistentHeader(
          pinned: true,
          delegate: StickyHeaderDelegate(
            height: topPadding + 12 + _searchBarHeight + 8 + _chipsRowHeight,
            blurBackground: true,
            child: Column(
              children: [
                SizedBox(height: topPadding),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          controller: _searchController,
                          hintText:
                              'Rechercher un profil, compétence, entreprise...',
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterIconButton(
                        onTap: () => _openFiltersSheet(context),
                      ),
                    ],
                  ),
                ),
                _buildCategoryChips(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Consumer<ExploreProvider>(
              builder: (context, provider, _) {
                // "Voir tout" seulement s'il y a effectivement plus que
                // les 5 profils affichés en aperçu ici — soit déjà chargés
                // au-delà de 5, soit d'autres pages disponibles côté
                // serveur (hasMore).
                final hasMoreThanPreview =
                    provider.users.length > 5 || provider.hasMore;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profils suggérés pour vous',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (hasMoreThanPreview)
                      GestureDetector(
                        onTap: _openAllProfiles,
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
                );
              },
            ),
          ),
        ),
        _buildUsersSliver(),
        SliverToBoxAdapter(child: _buildCommunitiesSection()),
        const SliverToBoxAdapter(child: _CreateNetworkBanner()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 16 +
                BottomNavMetrics.bottomInset(
                    MediaQuery.of(context).padding.bottom),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: _chipsRowHeight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'Pour vous',
            icon: Icons.auto_awesome_rounded,
            active: _activeChip == 'pour_vous',
            onTap: () {
              setState(() => _activeChip = 'pour_vous');
              if (_provider.jobTitleFilter.isNotEmpty) {
                _provider.setJobTitleFilter('');
              }
            },
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Fonctions',
            icon: Icons.work_outline_rounded,
            active: _activeChip == 'fonctions',
            onTap: () {
              setState(() => _activeChip = 'fonctions');
              _openJobTitleFilter(context);
            },
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Compétences',
            icon: Icons.star_outline_rounded,
            active: _activeChip == 'competences',
            // Purement visuel pour l'instant — cf. commentaire sur
            // _activeChip.
            onTap: () => setState(() => _activeChip = 'competences'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Réseaux',
            icon: Icons.people_outline_rounded,
            active: _activeChip == 'reseaux',
            onTap: () => setState(() => _activeChip = 'reseaux'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSliver() {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverPadding(
            padding: EdgeInsets.only(top: 40),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (provider.error != null) {
          return SliverPadding(
            padding: const EdgeInsets.only(top: 40),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
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
            ),
          );
        }

        if (provider.users.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: Column(
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

        // Aperçu limité à 5 — la liste complète est derrière "Voir tout"
        // (AllProfilesPage), pas ici : pas de défilement infini sur cette
        // page, donc pas d'indicateur de chargement de page suivante.
        final preview = provider.users.take(5).toList();
        return SliverList.builder(
          itemCount: preview.length,
          itemBuilder: (context, index) => ExploreUserRow(user: preview[index]),
        );
      },
    );
  }

  Widget _buildCommunitiesSection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        // Rien à afficher tant qu'aucune communauté n'a été créée par le
        // superadmin, ou en cas d'échec réseau.
        if (!provider.isLoading && provider.communities.isEmpty) {
          return const SizedBox.shrink();
        }
        return const _CommunitiesSection();
      },
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.onSurface.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.tune_rounded,
              color: colors.onSurface.withValues(alpha: 0.7), size: 20),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: active ? _themeBlue : colors.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: active
                      ? Colors.white
                      : colors.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Colors.white
                      : colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// "Réseaux populaires" — carrousel horizontal de communautés (cf.
/// maquette). Superadmin only pour la gestion des communautés elles-mêmes
/// (CRM web) ; ici on ne fait que lister/rejoindre.
class _CommunitiesSection extends StatelessWidget {
  const _CommunitiesSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              height: 196,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 196,
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

/// Bandeau promotionnel (cf. maquette) — la création d'un réseau par un
/// utilisateur lui-même n'existe pas encore côté backend (aujourd'hui,
/// seul le superadmin crée des communautés depuis le CRM web) : le tap
/// affiche donc un message plutôt qu'une navigation vers une fonctionnalité
/// qui n'existe pas.
class _CreateNetworkBanner extends StatelessWidget {
  const _CreateNetworkBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bientôt disponible')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _themeBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_outlined, color: _themeBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créez votre propre réseau',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Rassemblez votre communauté autour de vos centres d'intérêt",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: colors.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

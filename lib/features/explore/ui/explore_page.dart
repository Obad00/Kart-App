import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../../auth/providers/auth_provider.dart';
import '../../jobmatch/ui/jobmatch_feed_page.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/connection_badge_provider.dart';
import '../providers/explore_discovery_provider.dart';
import '../providers/explore_provider.dart';
import '../services/community_service.dart';
import '../services/company_discovery_service.dart';
import '../services/explore_service.dart';
import '../widgets/category_tile.dart';
import '../widgets/community_card.dart';
import '../widgets/company_discover_card.dart';
import '../widgets/explore_profile_card.dart';
import '../widgets/explore_section_header.dart';
import '../widgets/profile_carousel.dart';
import 'all_profiles_page.dart';
import 'communities_page.dart';
import 'companies_discover_page.dart';
import 'company_detail_page.dart';
import 'community_members_page.dart';
import 'my_requests_page.dart';
import 'section_profiles_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/sticky_header_delegate.dart';

const _themeBlue = exploreThemeBlue;

/// "Explorer" — annuaire des utilisateurs KART avec une carte publique
/// active. Envoyer une demande de mise en relation notifie l'autre
/// personne par mail (avec des liens Accepter/Refuser, sans connexion
/// requise) ; si elle accepte, un contact se crée automatiquement des deux
/// côtés. "Mes demandes" (accepter/refuser directement dans l'app) est un
/// écran séparé (cf. MyRequestsPage), ouvert depuis le bouton filtre.
///
/// Refonte (cf. maquette fournie) : la page enchaîne désormais plusieurs
/// carrousels — profils recommandés, réseaux, profils certifiés, votre
/// secteur, nouveaux profils, près de vous, catégories, entreprises — la
/// puce active filtre lesquels sont affichés plutôt que de changer la
/// liste "Profils recommandés" elle-même comme avant.
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
  late final ExploreDiscoveryProvider _discoveryProvider;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  // Puce active sous la recherche — filtre quels carrousels sont affichés
  // ('tous' = tout). 'opportunites' ne filtre rien : elle navigue
  // directement vers JobMatch (cf. _onOpportunitiesTap), Explorer n'ayant
  // pas sa propre liste d'opportunités.
  String _activeChip = 'tous';

  bool _showFor(Set<String> chips) =>
      _activeChip == 'tous' || chips.contains(_activeChip);

  @override
  void initState() {
    super.initState();
    _provider = ExploreProvider(ExploreService());
    _communityProvider = CommunityProvider(CommunityService());
    _discoveryProvider =
        ExploreDiscoveryProvider(ExploreService(), CompanyDiscoveryService());

    // addPostFrameCallback : ces load() notifient leurs providers
    // (notifyListeners() dès leur première ligne, avant le moindre await)
    // — appelés à cru ici, ça arrivait en plein passage de build de
    // HomeShell (ExplorePage est l'un des 5 onglets de l'IndexedStack,
    // monté dès l'arrivée sur /home), provoquant "setState() or
    // markNeedsBuild() called during build" et corrompant le rendu de
    // l'écran suivant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _communityProvider.loadCommunities();
      _provider.loadUsers();
      _discoveryProvider.loadAll();

      if (widget.initialTabIndex == 1) _openMyRequests();
    });
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
    _discoveryProvider.dispose();
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

  void _openSectionProfiles(String section, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionProfilesPage(section: section, title: title),
      ),
    );
  }

  void _openCompaniesDiscover() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _discoveryProvider,
          child: const CompaniesDiscoverPage(),
        ),
      ),
    );
  }

  /// Puce "Opportunités" — Explorer n'a pas sa propre liste d'offres,
  /// JobMatch (onglet "Offres", réservé au plan Pro) en tient déjà lieu.
  void _onOpportunitiesTap(BuildContext context) {
    HapticFeedback.selectionClick();
    if (!context.read<AuthProvider>().isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Les opportunités JobMatch sont réservées au plan Pro.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        // JobMatchFeedPage n'a volontairement pas son propre Scaffold
        // (elle compte sur celui de HomeShell quand elle est un onglet) —
        // ouverte seule ici, il lui en faut un pour avoir un fond thémé
        // (sinon fond blanc par défaut, quel que soit le thème sombre/clair).
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const JobMatchFeedPage(),
        ),
      ),
    );
  }

  /// Bottom sheet ouverte par le bouton rond à côté de la recherche —
  /// donne accès à "Mes demandes" et au filtre par poste.
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
              if (_provider.jobTitles.isNotEmpty) ...[
                const Divider(height: 24),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openJobTitleFilter(context);
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
                          child: const Icon(Icons.work_outline_rounded,
                              color: _themeBlue),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrer par poste',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _provider.jobTitleFilter.isEmpty
                                    ? 'Tous postes'
                                    : _provider.jobTitleFilter,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.55),
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Sélection de poste (chips) en bottom sheet — cf. "Filtrer par poste"
  /// dans la sheet des filtres.
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
        ChangeNotifierProvider.value(value: _discoveryProvider),
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

        // Profils recommandés pour vous — le titre était affiché quel que
        // soit le filtre actif (seul le contenu en dessous était masqué),
        // donnant l'impression que "Profils recommandés" s'affichait aussi
        // sous "Entreprises"/"Réseaux". Header et contenu suivent
        // maintenant le même filtre.
        if (_showFor({'profils'}))
          SliverPadding(
            padding: const EdgeInsets.only(top: 12),
            sliver: SliverToBoxAdapter(child: _buildRecommendedSection()),
          ),

        if (_showFor({'reseaux'}))
          SliverToBoxAdapter(child: _buildCommunitiesSection()),

        if (_showFor({'profils'})) ...[
          SliverToBoxAdapter(child: _buildCertifiedSection()),
          SliverToBoxAdapter(child: _buildSectorSection()),
          SliverToBoxAdapter(child: _buildWeeklySection()),
        ],

        if (_showFor({'reseaux'}))
          SliverToBoxAdapter(child: _buildJoinableCommunitiesSection()),

        if (_showFor({'profils'})) ...[
          SliverToBoxAdapter(child: _buildNewProfilesSection()),
          SliverToBoxAdapter(child: _buildNearYouSection()),
        ],

        if (_showFor({'entreprises'})) ...[
          SliverToBoxAdapter(child: _buildCategoriesSection()),
          SliverToBoxAdapter(child: _buildCompaniesSection()),
        ],

        if (_showFor({'reseaux'}))
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
            label: 'Tous',
            icon: Icons.auto_awesome_rounded,
            active: _activeChip == 'tous',
            onTap: () => setState(() => _activeChip = 'tous'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Profils',
            icon: Icons.people_alt_outlined,
            active: _activeChip == 'profils',
            onTap: () => setState(() => _activeChip = 'profils'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Réseaux',
            icon: Icons.groups_outlined,
            active: _activeChip == 'reseaux',
            onTap: () => setState(() => _activeChip = 'reseaux'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Entreprises',
            icon: Icons.apartment_outlined,
            active: _activeChip == 'entreprises',
            onTap: () => setState(() => _activeChip = 'entreprises'),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Opportunités',
            icon: Icons.work_outline_rounded,
            active: false,
            onTap: () => _onOpportunitiesTap(context),
          ),
        ],
      ),
    );
  }

  /// "Profils recommandés pour vous" — même disposition que les autres
  /// carrousels de la page (ProfileCarousel : en-tête + cartes horizontales),
  /// plutôt que l'ancienne liste verticale de lignes (ExploreUserRow,
  /// toujours utilisée elle sur "Voir tout"/AllProfilesPage). Garde ses
  /// propres états chargement/erreur/vide car — contrairement aux
  /// carrousels "annexes" — cette section reste toujours affichée.
  Widget _buildRecommendedSection() {
    return Consumer<ExploreProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.only(top: 40, bottom: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 20),
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
          );
        }

        if (provider.users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
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
          );
        }

        // Aperçu limité à 5 — la liste complète est derrière "Voir tout"
        // (AllProfilesPage), pas ici : pas de défilement infini sur cette
        // page, donc pas d'indicateur de chargement de page suivante.
        final preview = provider.users.take(5).toList();
        final hasMoreThanPreview =
            provider.users.length > 5 || provider.hasMore;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExploreSectionHeader(
                title: 'Profils recommandés pour vous',
                subtitle: 'Des professionnels sélectionnés selon vos intérêts',
                onSeeAll: hasMoreThanPreview ? _openAllProfiles : null,
              ),
              SizedBox(
                height: 236,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      ExploreProfileCard(user: preview[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunitiesSection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoading && provider.communities.isEmpty) {
          return const SizedBox.shrink();
        }
        return _CommunitiesSection(
          title: 'Réseaux populaires',
          subtitle:
              'Les communautés professionnelles que la communauté KART rejoint le plus',
          communities: provider.communities,
          isLoading: provider.isLoading,
          onToggleJoin: provider.toggleJoin,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const CommunitiesPage(),
                    )),
          ),
        );
      },
    );
  }

  Widget _buildJoinableCommunitiesSection() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        final joinable =
            provider.communities.where((c) => !c.isJoined).toList();
        if (!provider.isLoading && joinable.isEmpty) {
          return const SizedBox.shrink();
        }
        return _CommunitiesSection(
          title: 'Réseaux à rejoindre',
          subtitle: 'Trouvez les communautés qui correspondent à vos ambitions',
          communities: joinable,
          isLoading: provider.isLoading,
          onToggleJoin: provider.toggleJoin,
        );
      },
    );
  }

  Widget _buildCertifiedSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) => ProfileCarousel(
        title: 'Profils certifiés',
        subtitle: 'Des profils vérifiés pour des connexions de confiance',
        users: provider.certified,
        onSeeAll: provider.certified.isEmpty
            ? null
            : () => _openSectionProfiles('certified', 'Profils certifiés'),
      ),
    );
  }

  Widget _buildSectorSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) => ProfileCarousel(
        title: 'Les profils qui font votre secteur',
        subtitle: 'Découvrez les professionnels de votre domaine',
        users: provider.sector,
        onSeeAll: provider.sector.isEmpty
            ? null
            : () => _openSectionProfiles('sector', 'Votre secteur'),
      ),
    );
  }

  Widget _buildWeeklySection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) => ProfileCarousel(
        title: 'À découvrir cette semaine',
        subtitle: 'Des profils sélectionnés par KART',
        users: provider.weekly,
        onSeeAll: provider.weekly.isEmpty
            ? null
            : () => _openSectionProfiles('weekly', 'À découvrir cette semaine'),
      ),
    );
  }

  Widget _buildNewProfilesSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) => ProfileCarousel(
        title: 'Nouveaux profils sur KART',
        subtitle: 'Les professionnels qui viennent de rejoindre la communauté',
        users: provider.newProfiles,
        onSeeAll: provider.newProfiles.isEmpty
            ? null
            : () => _openSectionProfiles('new', 'Nouveaux profils'),
      ),
    );
  }

  Widget _buildNearYouSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) => ProfileCarousel(
        title: 'Professionnels près de vous',
        subtitle: 'Découvrez les personnes de votre écosystème',
        users: provider.nearYou,
        showCityInsteadOfCompany: true,
        onSeeAll: provider.nearYou.isEmpty
            ? null
            : () => _openSectionProfiles('near', 'Près de vous'),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) {
        final categories =
            provider.categories.where((c) => c.count > 0).toList();
        if (categories.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExploreSectionHeader(
                title: 'Explorer par catégorie',
                subtitle: "Trouvez ce qui vous intéresse",
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryTile(
                      category: category,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SectionProfilesPage(
                              category: category.name,
                              title: category.name,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompaniesSection() {
    return Consumer<ExploreDiscoveryProvider>(
      builder: (context, provider, _) {
        if (provider.companies.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExploreSectionHeader(
                title: 'Entreprises à découvrir',
                subtitle: 'Des entreprises qui recrutent et collaborent',
                onSeeAll: _openCompaniesDiscover,
              ),
              SizedBox(
                height: 214,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.companies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final company = provider.companies[index];
                    return CompanyDiscoverCard(
                      company: company,
                      onToggleFollow: () =>
                          provider.toggleFollowCompany(company),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompanyDetailPage(
                            companyId: company.id,
                            companyName: company.name,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
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

/// Carrousel horizontal de communautés — même widget pour "Réseaux
/// populaires" (toutes) et "Réseaux à rejoindre" (celles non rejointes),
/// cf. maquette fournie.
class _CommunitiesSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Community> communities;
  final bool isLoading;
  final ValueChanged<Community> onToggleJoin;
  final VoidCallback? onSeeAll;

  const _CommunitiesSection({
    required this.title,
    required this.subtitle,
    required this.communities,
    required this.isLoading,
    required this.onToggleJoin,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreSectionHeader(
            title: title,
            subtitle: subtitle,
            onSeeAll: communities.isNotEmpty ? onSeeAll : null,
          ),
          if (isLoading)
            const SizedBox(
              height: 196,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (communities.isEmpty)
            const SizedBox.shrink()
          else
            SizedBox(
              height: 196,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: communities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return SizedBox(
                    width: 220,
                    child: CommunityCard(
                      community: community,
                      onToggleJoin: () => onToggleJoin(community),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommunityMembersPage(
                            communityId: community.id,
                            communityName: community.name,
                          ),
                        ),
                      ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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

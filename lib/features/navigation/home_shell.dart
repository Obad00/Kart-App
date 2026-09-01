import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_update_service.dart';
import '../../shared/utils/jobmatch_access.dart';
import '../auth/providers/auth_provider.dart';
import '../digital_card/providers/card_provider.dart';
import '../digital_card/ui/my_digital_card_page.dart';
import '../jobmatch/ui/jobmatch_feed_page.dart';
import '../jobmatch/ui/jobmatch_matches_page.dart';
import '../profile/ui/profile_page.dart';
import '../profile_completion/helpers/completion_helper.dart';
import '../profile_completion/providers/candidate_skills_provider.dart';
import '../profile_completion/providers/profile_completion_provider.dart';
import '../profile_completion/ui/completion_form_page.dart';
// import '../scan/ui/card_scan_switcher_page.dart';
import '../contacts/ui/contacts_page.dart';
import '../explore/ui/explore_page.dart';
import '../../shared/tour/tour_prefs.dart';
import '../../shared/utils/session_reset.dart';
import '../explore/providers/connection_badge_provider.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  final bool forceTourReplay;

  /// Renseigné par les deep links `kart://jobmatch/liked` (mail d'intérêt
  /// candidat, onglet 1 = Aimées) et `kart://jobmatch/matches` (mail de
  /// match, onglet 0 = Matchs) — ouvre directement le tableau de bord
  /// JobMatch sur cet onglet au premier frame affiché. `null` = pas de
  /// deep link, comportement normal (tour guidé éventuel...).
  final int? openDashboardTab;

  /// Renseigné par le mail/la notification de demande de connexion
  /// (`kart://explore/requests`) — sélectionne l'onglet "Mes demandes" à
  /// l'intérieur d'Explorer. `null` = onglet "Découvrir" par défaut.
  final int? openExploreTab;

  const HomeShell({
    super.key,
    this.initialIndex = 0,
    this.forceTourReplay = false,
    this.openDashboardTab,
    this.openExploreTab,
  });
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _tourKey = 'tab_bar';
  // Rappel de complétion de profil : jusqu'à 3 fois par jour, avec au
  // moins 3h30 d'écart entre deux affichages (évite qu'il s'affiche
  // plusieurs fois quasi coup sur coup si l'app est rouverte plusieurs
  // fois d'affilée en peu de temps).
  static const _profileReminderMaxPerDay = 3;
  static const _profileReminderMinGap = Duration(hours: 3, minutes: 30);
  static const _profileReminderDateKey = 'profile_reminder_date';
  static const _profileReminderCountKey = 'profile_reminder_count';
  static const _profileReminderLastShownAtKey =
      'profile_reminder_last_shown_at';

  // Suivi de l'utilisateur pour lequel les données (profil, compétences,
  // contacts...) ont été chargées — statique pour survivre à un
  // remount de HomeShell (ex: après une déconnexion/reconnexion sans
  // redémarrage complet de l'app). Ces providers ne sont chargés qu'une
  // seule fois à la création de l'app ; sans ce suivi, rien ne les
  // rechargeait après un changement de session, et ils restaient vides.
  static int? _sessionDataLoadedForUserId;

  late int _index;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  // Une clé par slot de nav (5 slots toujours alloués, comme pour
  // _scaleControllers — le 5e, JobMatch, n'est simplement pas montré au
  // tour si l'item n'est pas rendu pour cet utilisateur).
  final List<GlobalKey> _navKeys = List.generate(5, (_) => GlobalKey());

  // Éléments de l'onglet Carte également inclus dans le tour (visibles
  // seulement quand cet onglet est actif, cf. _maybeStartTour).
  final GlobalKey _highlightBarKey = GlobalKey();
  final GlobalKey _createCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);

    // Créer les contrôleurs d'animation pour chaque item (5 slots toujours
    // alloués — le 5e, JobMatch, n'est simplement pas rendu si non-candidat).
    _scaleControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    _scaleAnimations = _scaleControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Migre l'ancien flag (avant l'introduction de TourPrefs) — sinon
      // tous les comptes qui avaient déjà vu le tour le revoient une fois
      // de plus sur cette version, et le rappel de profil reste bloqué en
      // attendant (cf. _maybeShowProfileReminder).
      await _migrateLegacyTourFlag();
      if (!mounted) return;

      // Un échec ici (réseau instable au tout début du lancement, souci
      // backend passager...) ne doit jamais empêcher le tour guidé, le
      // rappel de mise à jour et le rappel de profil de s'exécuter — sans
      // ce try/catch, une exception non rattrapée stoppait net le reste de
      // cette séquence de démarrage (les 3 appels suivants ne se
      // déclenchaient tout simplement jamais pour ce lancement).
      try {
        await _maybeReloadSessionData();
      } catch (e) {
        debugPrint('⚠️ _maybeReloadSessionData a échoué: $e');
      }
      if (!mounted) return;

      if (widget.openDashboardTab != null) {
        // Vient d'un deep link (mail d'intérêt candidat ou de match) :
        // priorité à la navigation demandée, pas de tour guidé cette
        // fois-ci pour ne pas superposer deux overlays.
        _openDashboardPage(widget.openDashboardTab!);
      } else {
        _maybeStartTour();
      }
      _maybeCheckForUpdate();
      _maybeShowProfileReminder();
    });
  }

  /// Recharge les données propres au compte (profil, compétences,
  /// contacts, highlights, carte) si elles ne l'ont pas déjà été pour cet
  /// utilisateur précis — couvre le cas d'une connexion fraîche après une
  /// déconnexion, sans redémarrage complet de l'app (où rien d'autre ne
  /// déclenche ce chargement, cf. session_reset.dart).
  Future<void> _maybeReloadSessionData() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId == _sessionDataLoadedForUserId) return;

    _sessionDataLoadedForUserId = userId;
    await loadSessionData(context);
  }

  static const _legacyTourSeenKey = 'has_seen_tab_tour';

  Future<void> _migrateLegacyTourFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_legacyTourSeenKey) == true &&
        !(await TourPrefs.hasSeen(_tourKey))) {
      await TourPrefs.markSeen(_tourKey);
    }
  }

  void _openDashboardPage(int tabIndex) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobMatchMatchesPage(initialTabIndex: tabIndex),
      ),
    );
  }

  /// Rappel doux (ignorable) si une version plus récente de l'app est
  /// disponible sur le store. Ne s'affiche pas si le tour guidé est sur le
  /// point de démarrer (première ouverture), pour éviter de superposer
  /// deux overlays — il sera simplement proposé au lancement suivant.
  Future<void> _maybeCheckForUpdate() async {
    if (!mounted) return;

    final tourAlreadySeen = await TourPrefs.hasSeen(_tourKey);
    if (!tourAlreadySeen && !widget.forceTourReplay) return;

    final info = await AppUpdateService.checkForUpdate();
    if (info == null || !mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mise à jour disponible'),
        content: Text(
          'Une nouvelle version de KART (${info.latestVersion}) est disponible. '
          'Mets à jour pour profiter des dernières améliorations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final uri = Uri.parse(info.storeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  /// Rappel doux, une fois par jour max, tant que le profil est sous 80% de
  /// complétude — jusqu'à 3 fois par jour (espacées d'au moins 3h30), ne
  /// s'affiche pas le jour du tout premier lancement (pour ne pas
  /// superposer avec le tour guidé).
  Future<void> _maybeShowProfileReminder() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);

    final storedDate = prefs.getString(_profileReminderDateKey);
    final countToday =
        storedDate == today ? (prefs.getInt(_profileReminderCountKey) ?? 0) : 0;
    if (countToday >= _profileReminderMaxPerDay) return;

    final lastShownAtMillis = prefs.getInt(_profileReminderLastShownAtKey);
    if (lastShownAtMillis != null) {
      final elapsed = now.difference(
        DateTime.fromMillisecondsSinceEpoch(lastShownAtMillis),
      );
      if (elapsed < _profileReminderMinGap) return;
    }

    // Laisse une chance au tour guidé (démarrage async : charge d'abord le
    // résumé de la carte) de s'afficher en premier s'il doit le faire, pour
    // ne pas superposer les deux overlays — sans pour autant dépendre d'un
    // flag "tour déjà vu" qui bloquerait le rappel toute la journée si ce
    // flag n'était pas encore posé (ex: juste après une mise à jour de l'app).
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (ShowCaseWidget.of(context).ids != null) return;

    if (!mounted) return;
    final completionProvider = context.read<ProfileCompletionProvider>();
    final skillsProvider = context.read<CandidateSkillsProvider>();
    if (completionProvider.loading || skillsProvider.loading) return;

    final result = CompletionHelper.calculate(
      completionProvider.model,
      hasSkills: skillsProvider.skills.isNotEmpty,
    );
    if (result.percent >= 80) return;

    await prefs.setString(_profileReminderDateKey, today);
    await prefs.setInt(_profileReminderCountKey, countToday + 1);
    await prefs.setInt(
        _profileReminderLastShownAtKey, now.millisecondsSinceEpoch);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) =>
          _ProfileReminderDialog(percent: result.percent),
    );
  }

  Future<void> _maybeStartTour() async {
    if (!mounted) return;

    if (!widget.forceTourReplay && await TourPrefs.hasSeen(_tourKey)) {
      return;
    }

    if (!mounted) return;

    final showJobMatch =
        canAccessJobMatch(context.read<AuthProvider>().user?.plan);

    final keys = <GlobalKey>[_navKeys[0]];

    // Highlights et "Créer ma carte" ne sont montés que si l'onglet Carte
    // (index 0) est bien celui affiché — c'est garanti par les deux points
    // d'entrée de ce tour (premier lancement : initialIndex par défaut à 0 ;
    // "Revoir le tutoriel" : navigue explicitement vers tab 0).
    if (_index == 0) {
      final cardProvider = context.read<CardProvider>();
      await cardProvider.loadCardSummary();
      if (!mounted) return;

      keys.add(_highlightBarKey);
      if (cardProvider.status == CardStatus.noCard) {
        keys.add(_createCardKey);
      }
    }

    keys.add(_navKeys[1]); // Contacts
    if (showJobMatch) keys.add(_navKeys[2]); // Offres
    keys.add(_navKeys[showJobMatch ? 3 : 2]); // Explorer
    keys.add(_navKeys[showJobMatch ? 4 : 3]); // Profil

    // Marqué "vu" dès le démarrage (pas à la fin) : que l'utilisateur suive
    // le guide jusqu'au bout ou clique "Passer" en cours de route, il ne
    // doit plus jamais redémarrer tout seul après.
    await TourPrefs.markSeen(_tourKey);
    if (!mounted) return;
    ShowCaseWidget.of(context).startShowCase(keys);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ConnectionBadgeProvider>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Widget> _pages(bool showJobMatch) {
    return [
      MyDigitalCardPage(
        highlightBarKey: _highlightBarKey,
        createCardKey: _createCardKey,
      ),
      const ContactsPage(),
      if (showJobMatch) const JobMatchFeedPage(),
      ExplorePage(initialTabIndex: widget.openExploreTab ?? 0),
      const ProfilePage(),
    ];
  }

  void _onTap(int idx) {
    if (_index == idx) return;
    HapticFeedback.lightImpact();
    // Le badge n'est plus effacé ici : simplement ouvrir Explorer ne veut
    // pas dire qu'on a vu les demandes en attente. Il ne s'efface qu'à
    // l'ouverture réelle de l'onglet "Mes demandes" (voir explore_page.dart),
    // qui affiche désormais le même badge pour ne rien perdre en route.
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (!auth.isAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return const Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (auth.user!.mustChangePassword) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/force-change-password');
        });
        return const Scaffold(
          backgroundColor: Color(0xFF000000),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final colors = Theme.of(context).colorScheme;
      final showJobMatch = canAccessJobMatch(auth.user?.plan);
      final pages = _pages(showJobMatch);
      final safeIndex = _index.clamp(0, pages.length - 1);

      return Scaffold(
        backgroundColor: colors.surface,
        // extendBody retiré : chaque page de cet onglet a son propre
        // Scaffold avec un fond plein (ContactsPage, JobMatchFeedPage...),
        // qui remplissait alors toute la hauteur — y compris derrière la
        // pilule de nav. Résultat : pas de vrai contenu flouté, juste un
        // bloc de couleur unie visible derrière/autour de la pilule (le
        // "fond" qui n'a pas sa place là).
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(safeIndex),
            child: pages[safeIndex],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(colors, showJobMatch),
      );
    });
  }

  Widget _buildBottomNavigation(ColorScheme colors, bool showJobMatch) {
    final badgeCount =
        context.watch<ConnectionBadgeProvider>().pendingReceivedCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sans extendBody, cette pilule flotte simplement au-dessus du fond
    // plein du Scaffold (celui de la page active, ou le nôtre) — toujours
    // un flou/tint verre dépoli, juste sans la couche de contenu qui
    // défile derrière (retirée, voir plus haut).
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                // Verre dépoli façon Apple : un tint semi-transparent de la
                // couleur de surface plutôt qu'un fond plein — opacité basse
                // pour que le flou (et ce qui défile dessous) reste visible,
                // même en thème sombre.
                color: colors.surface.withValues(alpha: isDark ? 0.32 : 0.55),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.credit_card_outlined,
                    activeIcon: Icons.credit_card,
                    label: 'Carte',
                    index: 0,
                    tourDescription:
                        'Votre carte de visite digitale, personnalisable et prête à partager. Retournez-la pour scanner un code QR.',
                  ),
                  _buildNavItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Contacts',
                    index: 1,
                    tourDescription:
                        'Retrouvez tous les contacts collectés au même endroit.',
                  ),
                  if (showJobMatch)
                    _buildNavItem(
                      icon: Icons.favorite_outline,
                      activeIcon: Icons.favorite,
                      label: 'Offres',
                      index: 2,
                      tourDescription:
                          "Découvrez les offres d'emploi qui correspondent à votre profil.",
                    ),
                  _buildNavItem(
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore,
                    label: 'Explorer',
                    index: showJobMatch ? 3 : 2,
                    tourDescription:
                        'Découvrez d\'autres utilisateurs KART et connectez-vous avec eux.',
                    badgeCount: badgeCount,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                    index: showJobMatch ? 4 : 3,
                    tourDescription:
                        'Gérez vos informations, votre carte et les réglages de l\'app.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String tourDescription,
    bool isSpecial = false,
    int badgeCount = 0,
  }) {
    final selected = _index == index;
    final colors = Theme.of(context).colorScheme;
    final cardProvider = context.watch<CardProvider>();

    // Utiliser la couleur de l'entreprise si disponible
    final primaryColor = _getCompanyColor(cardProvider) ?? colors.primary;
    final inactiveColor = colors.onSurface.withValues(alpha: 0.4);

    return Expanded(
      child: Showcase(
        key: _navKeys[index],
        title: label,
        description: tourDescription,
        targetShapeBorder: const CircleBorder(),
        child: GestureDetector(
          onTapDown: (_) => _scaleControllers[index].forward(),
          onTapUp: (_) {
            _scaleControllers[index].reverse();
            _onTap(index);
          },
          onTapCancel: () => _scaleControllers[index].reverse(),
          behavior: HitTestBehavior.opaque,
          child: ScaleTransition(
            scale: _scaleAnimations[index],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône avec animation et badge optionnel
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: isSpecial && selected
                            ? Container(
                                key: ValueKey('special_$selected'),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  activeIcon,
                                  key: ValueKey('icon_${index}_$selected'),
                                  color: Colors.white,
                                  size: 18,
                                ),
                              )
                            : Icon(
                                selected ? activeIcon : icon,
                                key: ValueKey('icon_${index}_$selected'),
                                color: selected ? primaryColor : inactiveColor,
                                size: 22,
                              ),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -5,
                          right: -7,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Label animé à côté de l'icône quand sélectionné
                  Flexible(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: selected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Parse la couleur de l'entreprise depuis le provider
  Color? _getCompanyColor(CardProvider cardProvider) {
    final hexColor = cardProvider.companyPrimaryColor;
    if (hexColor == null || hexColor.isEmpty) return null;
    try {
      String hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}

/// Rappel de complétion de profil — même langage visuel que CompletionBanner
/// (onglet Profil) : carte à dégradé ambre, icône fusée, barre de
/// progression — plutôt qu'une AlertDialog générique du système.
class _ProfileReminderDialog extends StatelessWidget {
  final double percent;

  const _ProfileReminderDialog({required this.percent});

  static const _accentColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = percent / 100;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accentColor.withValues(alpha: 0.18),
                    _accentColor.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                size: 26,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Complétez votre profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Un profil complet augmente vos chances d\'être remarqué par les recruteurs.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: colors.onSurface.withValues(alpha: 0.08),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${percent.toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Plus tard',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => const CompletionFormPage(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Compléter',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

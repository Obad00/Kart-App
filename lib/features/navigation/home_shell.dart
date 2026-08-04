import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../shared/utils/jobmatch_access.dart';
import '../auth/providers/auth_provider.dart';
import '../digital_card/providers/card_provider.dart';
import '../digital_card/ui/my_digital_card_page.dart';
import '../jobmatch/ui/jobmatch_feed_page.dart';
import '../profile/ui/profile_page.dart';
// import '../scan/ui/card_scan_switcher_page.dart';
import '../contacts/ui/contacts_page.dart';
import '../scan/ui/scan_page.dart';


class HomeShell extends StatefulWidget {
  final int initialIndex;
  final bool forceTourReplay;
  const HomeShell({
    super.key,
    this.initialIndex = 0,
    this.forceTourReplay = false,
  });
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  static const _tourSeenKey = 'has_seen_tab_tour';

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _maybeStartTour() async {
    if (!mounted) return;

    if (!widget.forceTourReplay) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_tourSeenKey) ?? false) return;
    }

    if (!mounted) return;

    final showJobMatch = canAccessJobMatch(context.read<AuthProvider>().user?.plan);

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

    keys.add(_navKeys[1]); // Scan
    keys.add(_navKeys[2]); // Contacts
    if (showJobMatch) keys.add(_navKeys[3]); // Offres
    keys.add(_navKeys[showJobMatch ? 4 : 3]); // Profil

    ShowCaseWidget.of(context).startShowCase(keys);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourSeenKey, true);
  }

  @override
  void dispose() {
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
      const ScanPage(),
      const ContactsPage(),
      if (showJobMatch) const JobMatchFeedPage(),
      const ProfilePage(),
    ];
  }

  void _onTap(int idx) {
    if (_index == idx) return;
    HapticFeedback.lightImpact();
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
          Navigator.of(context)
              .pushReplacementNamed('/force-change-password');
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
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
                      'Votre carte de visite digitale, personnalisable et prête à partager.',
                ),
                _buildNavItem(
                  icon: Icons.qr_code_scanner_outlined,
                  activeIcon: Icons.qr_code_scanner,
                  label: 'Scan',
                  index: 1,
                  isSpecial: true,
                  tourDescription:
                      'Scannez un code QR pour échanger vos coordonnées instantanément.',
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Contacts',
                  index: 2,
                  tourDescription:
                      'Retrouvez tous les contacts collectés au même endroit.',
                ),
                if (showJobMatch)
                  _buildNavItem(
                    icon: Icons.favorite_outline,
                    activeIcon: Icons.favorite,
                    label: 'Offres',
                    index: 3,
                    tourDescription:
                        "Découvrez les offres d'emploi qui correspondent à votre profil.",
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
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required String tourDescription,
    bool isSpecial = false,
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
                // Icône avec animation
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
                                color: primaryColor.withValues(alpha: 0.3),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../digital_card/providers/card_provider.dart';
import '../digital_card/ui/my_digital_card_page.dart';
import '../profile/ui/profile_page.dart';
// import '../scan/ui/card_scan_switcher_page.dart';
import '../contacts/ui/contacts_page.dart';
import '../scan/ui/scan_page.dart';


class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({
    super.key,
    this.initialIndex = 0,
  });
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  late int _index;
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;

    // Créer les contrôleurs d'animation pour chaque item
    _scaleControllers = List.generate(
      4,
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
  }

  @override
  void dispose() {
    for (var controller in _scaleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  static const List<Widget> _pages = <Widget>[
    MyDigitalCardPage(),
    ScanPage(),
    ContactsPage(),
    ProfilePage(),
  ];

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
            key: ValueKey<int>(_index),
            child: _pages[_index],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(colors),
      );
    });
  }

  Widget _buildBottomNavigation(ColorScheme colors) {
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
                ),
                _buildNavItem(
                  icon: Icons.qr_code_scanner_outlined,
                  activeIcon: Icons.qr_code_scanner,
                  label: 'Scan',
                  index: 1,
                  isSpecial: true,
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Contacts',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  index: 3,
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
    bool isSpecial = false,
  }) {
    final selected = _index == index;
    final colors = Theme.of(context).colorScheme;
    final cardProvider = context.watch<CardProvider>();

    // Utiliser la couleur de l'entreprise si disponible
    final primaryColor = _getCompanyColor(cardProvider) ?? colors.primary;
    final inactiveColor = colors.onSurface.withValues(alpha: 0.4);

    return Expanded(
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
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

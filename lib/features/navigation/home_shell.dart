import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../digital_card/ui/my_digital_card_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    MyDigitalCardPage(),
    _ScanPlaceholder(),
    _ContactsPlaceholder(),
    _ProfilePlaceholder(),
  ];

  void _onTap(int idx) {
    if (_index == idx) return;
    setState(() => _index = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, _) {
      if (!auth.isAuthenticated) {
        // If user is not authenticated, redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
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
          child: _pages[_index],
        ),
        bottomNavigationBar: _buildBottomNavigation(colors),
      );
    });
  }

  Widget _buildBottomNavigation(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
            top: BorderSide(
                color: colors.onSurface.withAlpha((0.06 * 255).round()))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
            children: [
              Expanded(child: _buildItem(icon: Icons.credit_card, label: 'Carte', index: 0)),
              Expanded(child: _buildItem(icon: Icons.qr_code_scanner, label: 'Scan', index: 1)),
              Expanded(child: _buildItem(icon: Icons.people, label: 'Contacts', index: 2)),
              Expanded(child: _buildItem(icon: Icons.person, label: 'Profil', index: 3)),
            ],
          ),
      ),
    );
  }

  Widget _buildItem(
      {required IconData icon, required String label, required int index}) {
    final selected = _index == index;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context)
            .colorScheme
            .onSurface
            .withAlpha((0.5 * 255).round());

    return GestureDetector(
      onTap: () => _onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding:
            EdgeInsets.symmetric(vertical: 8, horizontal: selected ? 18 : 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.04 * 255).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child:Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: selected ? 22 : 20),
            if (selected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanPlaceholder extends StatelessWidget {
  const _ScanPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Scanner',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      );
}

class _ContactsPlaceholder extends StatelessWidget {
  const _ContactsPlaceholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Contacts',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      );
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Profil',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      );
}

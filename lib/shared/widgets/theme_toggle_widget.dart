import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

/// Sélecteur du thème de l'application — Clair / Sombre / Système (suit le
/// réglage du téléphone). Accessible à tous les utilisateurs.
class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor(themeProvider.themeMode).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _icon(themeProvider.themeMode),
                  color: _iconColor(themeProvider.themeMode),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thème de l\'application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label(themeProvider.themeMode),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSegmentedControl(context, themeProvider),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegment(
            context,
            themeProvider,
            mode: ThemeMode.light,
            icon: Icons.light_mode_rounded,
            label: 'Clair',
          ),
          _buildSegment(
            context,
            themeProvider,
            mode: ThemeMode.dark,
            icon: Icons.dark_mode_rounded,
            label: 'Sombre',
          ),
          _buildSegment(
            context,
            themeProvider,
            mode: ThemeMode.system,
            icon: Icons.brightness_auto_rounded,
            label: 'Système',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    ThemeProvider themeProvider, {
    required ThemeMode mode,
    required IconData icon,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;
    final active = themeProvider.themeMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await themeProvider.setThemeMode(mode, isPremiumOrCompany: true);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  Color _iconColor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Colors.amber;
      case ThemeMode.dark:
        return Colors.indigo;
      case ThemeMode.system:
        return Colors.teal;
    }
  }

  String _label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Mode clair activé';
      case ThemeMode.dark:
        return 'Mode sombre activé';
      case ThemeMode.system:
        return 'Suit le réglage du téléphone';
    }
  }
}

/// Widget compact pour la barre de navigation ou l'en-tête — bascule
/// simplement entre clair et sombre (le mode système reste accessible via
/// le sélecteur complet dans les réglages).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bool isLightMode = themeProvider.isLightMode;

    return IconButton(
      onPressed: () async {
        await themeProvider.toggleTheme(isPremiumOrCompany: true);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Icon(
          isLightMode ? Icons.dark_mode : Icons.light_mode,
          key: ValueKey(isLightMode),
          color: isLightMode ? Colors.indigo : Colors.amber,
        ),
      ),
      tooltip: isLightMode ? 'Activer le mode sombre' : 'Activer le mode clair',
    );
  }
}

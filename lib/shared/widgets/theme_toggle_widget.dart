import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

/// Widget pour basculer entre le mode Light et Dark
/// Accessible à tous les utilisateurs
class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bool isLightMode = themeProvider.isLightMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLightMode
                  ? Colors.amber.withValues(alpha: 0.15)
                  : Colors.indigo.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isLightMode ? Icons.light_mode : Icons.dark_mode,
              color: isLightMode ? Colors.amber : Colors.indigo,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLightMode ? 'Mode clair activé' : 'Mode sombre activé',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildThemeSwitch(context, themeProvider, isLightMode),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(
    BuildContext context,
    ThemeProvider themeProvider,
    bool isLightMode,
  ) {
    return GestureDetector(
      onTap: () async {
        await themeProvider.toggleTheme(isPremiumOrCompany: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isLightMode
              ? const LinearGradient(
                  colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
                )
              : LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                ),
          boxShadow: [
            BoxShadow(
              color: isLightMode
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.indigo.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: isLightMode ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isLightMode ? Icons.light_mode : Icons.dark_mode,
              size: 16,
              color: isLightMode ? Colors.amber : Colors.indigo,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget compact pour la barre de navigation ou l'en-tête
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

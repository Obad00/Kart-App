import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/connectivity_provider.dart';

/// Bandeau fin affiché en haut de l'écran quand l'appareil n'a plus de
/// connexion — les données déjà chargées restent visibles (cache disque
/// côté ApiClient), ce bandeau sert juste à prévenir l'utilisateur que ce
/// qu'il voit peut ne plus être à jour et que les actions réseau sont
/// indisponibles pour l'instant.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityProvider, bool>(
      (p) => p.isOnline,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : Material(
              key: const ValueKey('offline'),
              color: const Color(0xFFEF4444),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_off_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Vous êtes hors ligne',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'success_message.dart';

class FeedbackOverlay {
  // 2s ne laissait quasiment pas le temps de lire le message (surtout
  // "subtitle" en plus du titre) avant qu'il ne disparaisse d'un coup —
  // remonté comme "la notification se ferme trop vite". Porté à 3.5s, avec
  // en plus une vraie animation de sortie (fondu) au lieu d'une disparition
  // brutale une fois le timer écoulé.
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.check_circle,
      iconColor: Colors.greenAccent,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _show(
      context,
      title: title,
      subtitle: subtitle,
      icon: Icons.info,
       iconColor: Colors.black,
      duration: duration,
    );
  }

  /// 🔒 Méthode interne partagée
  static void _show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final visible = ValueNotifier<bool>(true);

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 60,
        left: 0,
        right: 0,
        child: SafeArea(
          child: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, isVisible, child) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: isVisible ? -20 : 0, end: isVisible ? 0 : -20),
                duration: Duration(milliseconds: isVisible ? 400 : 250),
                curve: isVisible ? Curves.easeOutCubic : Curves.easeInCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: Opacity(
                      opacity: isVisible
                          ? (value == -20 ? 0 : 1)
                          : (value == 0 ? 1 : 0),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            child: SuccessMessage(
              title: title,
              subtitle: subtitle,
              icon: icon,
              iconColor: iconColor,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Timer(duration, () {
      // Déclenche le fondu de sortie plutôt que de retirer l'entrée
      // instantanément, puis la retire vraiment une fois l'animation finie.
      visible.value = false;
      Timer(const Duration(milliseconds: 250), () {
        entry.remove();
        visible.dispose();
      });
    });
  }
}

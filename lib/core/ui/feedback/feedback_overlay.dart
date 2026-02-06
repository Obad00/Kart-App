import 'dart:async';
import 'package:flutter/material.dart';
import 'success_message.dart';

class FeedbackOverlay {
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String subtitle,
    Duration duration = const Duration(seconds: 2),
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
    Duration duration = const Duration(seconds: 2),
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

    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 60,
        left: 0,
        right: 0,
        child: SafeArea(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -20, end: 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(
                  opacity: value == -20 ? 0 : 1,
                  child: child,
                ),
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
      entry.remove();
    });
  }
}

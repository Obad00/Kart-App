import 'dart:ui';
import 'package:flutter/material.dart';

class QrFullscreenView extends StatelessWidget {
  final Widget qr;

  const QrFullscreenView({
    super.key,
    required this.qr,
  });

  static Future<void> show(BuildContext context, Widget qr) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'qr_fullscreen',
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) {
        return QrFullscreenView(qr: qr);
      },
      transitionBuilder: (_, anim, __, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutExpo);

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Stack(
        children: [
          // 🌫 Background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
              color: Colors.black.withValues(alpha: 0.15),
              ),
            ),
          ),

          // 📱 QR centré
          Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ],
              ),
              child: SizedBox(
                width: 260,
                height: 260,
                child: qr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/card_theme.dart';

class QrCard extends StatelessWidget {
  final Widget qr;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final DigitalCardTheme theme;

  const QrCard({
    super.key,
    required this.qr,
    required this.onShare,
    required this.onDownload,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(
          color: theme.border,
          width: theme.glow ? 0.4 : 0.6,
        ),
        boxShadow: _shadows(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: qr,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(Icons.share, onShare),
              _action(Icons.download, onDownload),
            ],
          ),
        ],
      ),
    );
  }

  List<BoxShadow> _shadows() {
    if (theme.glow) {
      // 🌑 DARK MINIMAL → glow premium
      return [
        BoxShadow(
          color: theme.foreground.withValues(alpha: 0.14),
          blurRadius: 40,
          spreadRadius: -6,
        ),
      ];
    }

    // 🌤 CLASSIQUE & CLEAN LIGHT
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: theme.elevation),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  Widget _action(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 18,
        color: theme.foreground,
      ),
    );
  }
}

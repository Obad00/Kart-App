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
        border: Border.all(color: theme.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.15),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 220, height: 220, child: qr),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(Icons.share),
              _action(Icons.download),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon) {
    return Icon(icon, size: 18, color: theme.foreground);
  }
}

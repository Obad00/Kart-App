import 'package:flutter/material.dart';

class QrCard extends StatelessWidget {
  final Widget qr;
  final VoidCallback onShare;
  final VoidCallback onDownload;

  const QrCard({
    super.key,
    required this.qr,
    required this.onShare,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 32,
            offset: const Offset(0, 16),
            color: Colors.black.withValues(alpha: 0.25),
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
              _action(Icons.share, onShare),
              _action(Icons.download, onDownload),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

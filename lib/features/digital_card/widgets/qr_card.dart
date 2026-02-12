import 'package:flutter/material.dart';
import '../theme/card_theme.dart';

class QrCard extends StatefulWidget {
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
  State<QrCard> createState() => _QrCardState();
}

class _QrCardState extends State<QrCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.theme.background,
                widget.theme.background.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.theme.border.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              // Glow animé
              BoxShadow(
                color: widget.theme.foreground.withValues(
                  alpha: 0.05 + (_pulseAnimation.value * 0.08),
                ),
                blurRadius: 40 + (_pulseAnimation.value * 20),
                spreadRadius: -5,
              ),
              // Ombre principale
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label "Scannez-moi"
              _buildScanLabel(),

              const SizedBox(height: 12),

              // QR Code avec frame décoratif
              _buildQrFrame(),

              const SizedBox(height: 16),

              // Actions stylisées
              _buildActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.theme.foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.theme.foreground.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 14,
            color: widget.theme.foreground.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 6),
          Text(
            'SCANNEZ-MOI',
            style: TextStyle(
              color: widget.theme.foreground.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrFrame() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.theme.foreground.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // QR Code
          SizedBox(
            width: 180,
            height: 180,
            child: widget.qr,
          ),

          // Coins décoratifs
          ..._buildCorners(),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const cornerSize = 24.0;
    const cornerWidth = 3.0;
    final cornerColor = widget.theme.foreground.withValues(alpha: 0.3);

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner(cornerSize, cornerWidth, cornerColor, 0),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner(cornerSize, cornerWidth, cornerColor, 1),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner(cornerSize, cornerWidth, cornerColor, 2),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner(cornerSize, cornerWidth, cornerColor, 3),
      ),
    ];
  }

  Widget _buildCorner(double size, double width, Color color, int position) {
    final BorderRadius borderRadius;
    final BoxDecoration decoration;

    switch (position) {
      case 0: // Top-left
        borderRadius = const BorderRadius.only(topLeft: Radius.circular(8));
        decoration = BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: width),
            left: BorderSide(color: color, width: width),
          ),
          borderRadius: borderRadius,
        );
        break;
      case 1: // Top-right
        borderRadius = const BorderRadius.only(topRight: Radius.circular(8));
        decoration = BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: width),
            right: BorderSide(color: color, width: width),
          ),
          borderRadius: borderRadius,
        );
        break;
      case 2: // Bottom-left
        borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(8));
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(color: color, width: width),
            left: BorderSide(color: color, width: width),
          ),
          borderRadius: borderRadius,
        );
        break;
      default: // Bottom-right
        borderRadius = const BorderRadius.only(bottomRight: Radius.circular(8));
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(color: color, width: width),
            right: BorderSide(color: color, width: width),
          ),
          borderRadius: borderRadius,
        );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: Icons.share_rounded,
          label: 'Partager',
          onTap: widget.onShare,
        ),
        const SizedBox(width: 16),
        _buildActionButton(
          icon: Icons.download_rounded,
          label: 'Télécharger',
          onTap: widget.onDownload,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [
                    widget.theme.foreground,
                    widget.theme.foreground.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isPrimary
              ? null
              : widget.theme.foreground.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: widget.theme.foreground.withValues(alpha: 0.15),
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: widget.theme.foreground.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary
                  ? widget.theme.background
                  : widget.theme.foreground.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? widget.theme.background
                    : widget.theme.foreground.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

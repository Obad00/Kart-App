import 'package:flutter/material.dart';

/// Carte QR basique pour les utilisateurs Freemium
/// Design minimaliste noir et blanc
class BasicQrCard extends StatefulWidget {
  final Widget qrCode;
  final String userName;
  final String? jobTitle;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback? onTapQr;

  const BasicQrCard({
    super.key,
    required this.qrCode,
    required this.userName,
    this.jobTitle,
    required this.onShare,
    required this.onDownload,
    this.onTapQr,
  });

  @override
  State<BasicQrCard> createState() => _BasicQrCardState();
}

class _BasicQrCardState extends State<BasicQrCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: IntrinsicHeight(
        child: Stack(
          children: [
            // Ombre portée
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
              ),
            ),
            // Carte principale
            Container(
              width: 290,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A1A1A),
                    Color(0xFF0D0D0D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header - Badge Freemium
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'KART',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code container
                  GestureDetector(
                    onTap: widget.onTapQr,
                    child: Container(
                      width: 170,
                      height: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: widget.qrCode,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nom utilisateur
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (widget.jobTitle != null &&
                      widget.jobTitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.jobTitle!,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: Icons.share_outlined,
                        onTap: widget.onShare,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: Icons.download_outlined,
                        onTap: widget.onDownload,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer
                  Text(
                    'Scannez pour me contacter',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Carte QR professionnelle avec branding entreprise
/// Design premium avec effets visuels avancés
class CompanyQrCard extends StatefulWidget {
  final Widget qrCode;
  final String companyName;
  final String? companyLogo;
  final Color primaryColor;
  final String? subtitle;
  final VoidCallback onShare;
  final VoidCallback onDownload;
  final VoidCallback? onTapQr;

  const CompanyQrCard({
    super.key,
    required this.qrCode,
    required this.companyName,
    this.companyLogo,
    required this.primaryColor,
    this.subtitle,
    required this.onShare,
    required this.onDownload,
    this.onTapQr,
  });

  @override
  State<CompanyQrCard> createState() => _CompanyQrCardState();
}

class _CompanyQrCardState extends State<CompanyQrCard>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late AnimationController _glowController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _floatAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Effet de flottement subtil
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // Effet shimmer sur les bords
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Glow pulsant
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Scale pour le feedback tactile
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Couleurs dérivées
  Color get _accentLight => Color.lerp(widget.primaryColor, Colors.white, 0.3)!;
  Color get _accentDark => Color.lerp(widget.primaryColor, Colors.black, 0.3)!;
  bool get _isLightColor => widget.primaryColor.computeLuminance() > 0.5;
  Color get _textOnPrimary => _isLightColor ? Colors.black87 : Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatAnimation,
        _shimmerAnimation,
        _glowAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapUp,
        child: Center(
          child: Container(
            width: 310,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                // Glow coloré animé
                BoxShadow(
                  color: widget.primaryColor.withOpacity(_glowAnimation.value * 0.35),
                  blurRadius: 40 + (_glowAnimation.value * 20),
                  spreadRadius: -8,
                ),
                // Ombre principale
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
                // Ombre secondaire
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    // Background avec gradient
                    Positioned.fill(child: _buildBackground()),
                    
                    // Effet de lumière animé
                    _buildLightEffect(),
                    
                    // Contenu principal
                    _buildContent(),
                    
                    // Bordure brillante
                    _buildShimmerBorder(),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0D0D0D),
            Color.lerp(const Color(0xFF0D0D0D), widget.primaryColor, 0.08)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildLightEffect() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _LightEffectPainter(
          color: widget.primaryColor,
          animation: _shimmerAnimation.value,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec logo et nom
            _buildHeader(),
            
            const SizedBox(height: 18),
            
            // QR Code avec frame stylisée
            _buildQrSection(),
            
            const SizedBox(height: 18),
            
            // Footer avec texte + Actions
            _buildFooterWithActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Logo de l'entreprise
        _buildLogo(),
        
        const SizedBox(width: 12),
        
        // Infos entreprise
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        
        // Badge coloré
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryColor, _accentLight],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'PRO',
            style: TextStyle(
              color: _textOnPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor.withOpacity(0.2),
            widget.primaryColor.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.companyLogo != null && widget.companyLogo!.isNotEmpty
            ? Image.network(
                widget.companyLogo!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildLogoPlaceholder(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildLogoPlaceholder();
                },
              )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.primaryColor, _accentDark],
        ),
      ),
      child: Center(
        child: Text(
          widget.companyName.isNotEmpty 
              ? widget.companyName[0].toUpperCase() 
              : 'K',
          style: TextStyle(
            color: _textOnPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  /// Logo placeholder pour le centre du QR code
  Widget _buildCenterLogoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.primaryColor, _accentDark],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          widget.companyName.isNotEmpty 
              ? widget.companyName[0].toUpperCase() 
              : 'K',
          style: TextStyle(
            color: _textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildQrSection() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTapQr?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.primaryColor.withOpacity(0.5),
              widget.primaryColor.withOpacity(0.2),
              _accentLight.withOpacity(0.3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // QR Code
              SizedBox(
                width: 190,
                height: 190,
                child: widget.qrCode,
              ),
              
              // Logo central sur le QR - affiche le logo de l'entreprise ou l'initiale
              Positioned(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.companyLogo != null && widget.companyLogo!.isNotEmpty
                        ? Image.network(
                            widget.companyLogo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildCenterLogoPlaceholder(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _buildCenterLogoPlaceholder();
                            },
                          )
                        : _buildCenterLogoPlaceholder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.primaryColor, _accentLight],
                )
              : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isPrimary
                ? widget.primaryColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isPrimary ? _textOnPrimary : Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  Widget _buildFooterWithActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Texte "Scannez-moi"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Scannez pour me contacter',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Boutons en dessous
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconButton(
              icon: Icons.share_rounded,
              onTap: widget.onShare,
              isPrimary: false,
            ),
            const SizedBox(width: 16),
            _buildIconButton(
              icon: Icons.download_rounded,
              onTap: widget.onDownload,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerBorder() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ShimmerBorderPainter(
            color: widget.primaryColor,
            animation: _shimmerAnimation.value,
            borderRadius: 26,
          ),
        ),
      ),
    );
  }

  void _onTapDown() {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp() {
    _scaleController.reverse();
  }
}

/// Painter pour l'effet de lumière
class _LightEffectPainter extends CustomPainter {
  final Color color;
  final double animation;

  _LightEffectPainter({required this.color, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          -0.5 + animation * 0.5,
          -0.8,
        ),
        radius: 1.2,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _LightEffectPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
}

/// Painter pour la bordure brillante
class _ShimmerBorderPainter extends CustomPainter {
  final Color color;
  final double animation;
  final double borderRadius;

  _ShimmerBorderPainter({
    required this.color,
    required this.animation,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Angle pour le shimmer
    final shimmerAngle = animation * 2 * math.pi;
    final shimmerX = math.cos(shimmerAngle);
    final shimmerY = math.sin(shimmerAngle);

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment(shimmerX * 0.5, shimmerY * 0.5),
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          Colors.transparent,
          color.withOpacity(0.3),
          color.withOpacity(0.6),
          color.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        transform: GradientRotation(shimmerAngle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerBorderPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.color != color;
  }
}

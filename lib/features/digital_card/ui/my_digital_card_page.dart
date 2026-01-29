import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_provider.dart';

class MyDigitalCardPage extends StatefulWidget {
  const MyDigitalCardPage({super.key});

  @override
  State<MyDigitalCardPage> createState() => _MyDigitalCardPageState();
}

class _MyDigitalCardPageState extends State<MyDigitalCardPage>
    with TickerProviderStateMixin {
  // Entrance animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // QR tap interaction
  late AnimationController _qrTapController;
  late Animation<double> _qrScaleAnimation;

  // Subtle loading pulse
  late AnimationController _loadingPulseController;
  late Animation<double> _loadingPulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadCardQr();
  }

  void _setupAnimations() {
    // Entrance animation (fade + scale)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // QR tap micro-interaction (scale bounce)
    _qrTapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _qrScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _qrTapController, curve: Curves.easeInOutCubic),
    );

    // Loading pulse (subtle breathing effect)
    _loadingPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _loadingPulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _loadingPulseController, curve: Curves.easeInOut),
    );
  }

  void _loadCardQr() {
    Future.microtask(() {
      if (mounted) {
        context.read<CardProvider>().loadMyCardQr();
      }
    });
  }

  void _onQrTap() {
    _qrTapController.forward().then((_) {
      _qrTapController.reverse();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _qrTapController.dispose();
    _loadingPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0A), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Header
              Positioned(
                top: 24,
                left: 24,
                child: Text(
                  'Ma Carte KART',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
              ),

              // Main Content
              Center(
                child: Consumer<CardProvider>(
                  builder: (context, cardProvider, _) {
                    // Loading State
                    if (cardProvider.isLoading) {
                      return _buildLoadingState();
                    }

                    // Error State
                    if (cardProvider.hasError) {
                      return _buildErrorState(
                        error: cardProvider.error ?? 'Erreur inconnue',
                        onRetry: _loadCardQr,
                      );
                    }

                    // Success State
                    if (cardProvider.hasQrCode) {
                      _fadeController.forward();
                      return ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildCardContent(cardProvider.qrSvg!),
                        ),
                      );
                    }

                    // Empty State
                    return _buildEmptyState(onRetry: _loadCardQr);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main card content with QR and micro-interactions
  Widget _buildCardContent(String svgQrCode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card Container with subtle glow
            _buildCardWithGlow(svgQrCode),

            const SizedBox(height: 48),

            // Description
            Column(
              children: [
                Text(
                  'Votre Code Unique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Partagez votre carte digitale KART en scannant ce code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card with subtle white glow effect
  Widget _buildCardWithGlow(String svgQrCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // Main shadow (depth)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          // Subtle shadow layer 2
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          // Subtle white glow (barely visible, premium feel)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 0),
            spreadRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(48),
      child: Center(
        child: GestureDetector(
          onTap: _onQrTap,
          child: ScaleTransition(
            scale: _qrScaleAnimation,
            child: SizedBox(
              width: 220,
              height: 220,
              child: _buildQrWithGlow(svgQrCode),
            ),
          ),
        ),
      ),
    );
  }

  /// QR code with subtle glow effect on tap
  Widget _buildQrWithGlow(String svgQrCode) {
    return AnimatedBuilder(
      animation: _qrScaleAnimation,
      builder: (context, child) {
        // Subtle glow intensifies on tap
        final glowOpacity =
            0.05 + (_qrScaleAnimation.value < 0.98 ? 0.08 : 0.0);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            // Glow effect on tap/hover
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: glowOpacity),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: _buildSvgPlaceholder(svgQrCode),
    );
  }

  /// Loading state with subtle pulse animation
  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _loadingPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _loadingPulseAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              // Subtle glow on loading container
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.02),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Chargement de votre carte...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  /// Error state with smooth entry animation
  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon with subtle glow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.05),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Error Message
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.65),
                letterSpacing: 0.2,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Retry Button with micro-interaction
            _buildRetryButton(onRetry),
          ],
        ),
      ),
    );
  }

  /// Empty state with smooth entry
  Widget _buildEmptyState({required VoidCallback onRetry}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_2,
              size: 40,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Aucune carte trouvée',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vérifiez votre profil et réessayez',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 32),
        _buildRetryButton(onRetry),
      ],
    );
  }

  /// Reusable retry button with hover effect
  Widget _buildRetryButton(VoidCallback onRetry) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'Réessayer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SVG placeholder for QR code display
  Widget _buildSvgPlaceholder(String svgQrCode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: Colors.black.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'QR Code SVG',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

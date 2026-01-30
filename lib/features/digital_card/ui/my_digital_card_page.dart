import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import '../../../shared/services/card_service.dart';
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

  // Slow scan-line animation for QR (subtle vertical loop)
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

 @override
void initState() {
  super.initState();
  _setupAnimations();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final card = context.read<CardProvider>();
    card.loadMyCardQr();
    card.loadCardSummary();
  });
}



  void _setupAnimations() {
    // Entrance animation (fade + scale)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutExpo),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutExpo),
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

    // QR scan line - slow vertical loop to suggest "active" scan
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  void _loadCardQr() {
    Future.microtask(() {
      if (mounted) {
        context.read<CardProvider>().loadMyCardQr();
      }
    });
  }

  // Simple card initials helper
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2)
          ? p.substring(0, 2).toUpperCase()
          : p.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // Card press state (micro-interaction)
  bool _cardPressed = false;

  // Key to capture QR widget as image for export
  final GlobalKey _qrKey = GlobalKey();

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
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Global auth info used by header
    final auth = context.watch<AuthProvider>();
    final fullName = auth.user != null
    
        ? (auth.user!['fullname'] ??
            ('${auth.user!['firstname'] ?? ''} ${auth.user!['lastname'] ?? ''}')
                .trim())
        : 'Utilisateur';
        final initialsText = _initials(fullName);

final card = context.watch<CardProvider>();

final jobTitle = card.jobTitle ?? '';
final company  = card.company ?? '';

final companyDisplay =
    company.isNotEmpty ? company : (jobTitle.isNotEmpty ? jobTitle : 'Membre');

    return Scaffold(
      backgroundColor: colors.surface,
      body: Container(
        decoration: BoxDecoration(color: colors.surface),
        child: SafeArea(
          child: Stack(
            children: [
              // Header (avatar, name, settings)
              Positioned(
                top: 18,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    // Bind user from global AuthProvider
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                         initialsText,
                          style: const TextStyle(
                              color: Color(0xFF0A0A0A),
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName.isNotEmpty ? fullName : 'Utilisateur',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(
                              companyDisplay.isNotEmpty
                                  ? companyDisplay
                                  : 'Membre',
                              style: TextStyle(
                                  color: colors.onSurface
                                      .withAlpha((0.75 * 255).round()),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {/* open profile/settings */},
                      icon: Icon(Icons.more_vert,
                          color: Theme.of(context).colorScheme.onSurface),
                      splashRadius: 20,
                    )
                  ],
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

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Card with subtle white glow effect
  Widget _buildCardWithGlow(String svgQrCode) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _cardPressed = true),
      onTapUp: (_) => setState(() => _cardPressed = false),
      onTapCancel: () => setState(() => _cardPressed = false),
      child: AnimatedScale(
        scale: _cardPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            // Main shadow (depth)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.25 * 255).round()),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              // Subtle shadow layer 2
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              // Subtle white glow (barely visible, premium feel)
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((0.03 * 255).round()),
                blurRadius: 24,
                offset: const Offset(0, 0),
                spreadRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _onQrTap,
                child: ScaleTransition(
                  scale: _qrScaleAnimation,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: RepaintBoundary(
                        key: _qrKey, child: _buildQrWithGlow(svgQrCode)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _cardAction(Icons.share, () => _openShareSheet(svgQrCode)),
                  _cardAction(
                      Icons.download, () => _exportQrImageAndShare(svgQrCode)),
                  _cardAction(Icons.more_horiz, () {/* more */}),
                ],
              ),
            ],
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            // Glow effect on tap/hover
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((glowOpacity * 255).round()),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.05 * 255).round()),
              borderRadius: BorderRadius.circular(16),
              // Subtle glow on loading container
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha((0.02 * 255).round()),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha((0.8 * 255).round()),
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((0.65 * 255).round()),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.qr_code_2,
              size: 40,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.5 * 255).round()),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha((0.65 * 255).round()),
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
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withAlpha((0.08 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withAlpha((0.15 * 255).round()),
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
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardAction(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0A0A0A), size: 18),
        ),
      ),
    );
  }

  /// Share bottom sheet and helpers
  void _openShareSheet(String svgQrCode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF000000),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.link,
                  color: Theme.of(context).colorScheme.onSurface),
              title: Text('Partager le lien public de la carte',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Navigator.of(ctx).pop();
                _sharePublicLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text('Exporter image du QR',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _exportQrImageAndShare(svgQrCode);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePublicLink() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await CardService.getCardShareLink();
      // Copy to clipboard for quick share and open native share sheet
      await Clipboard.setData(ClipboardData(text: url));
      await SharePlus.instance.share(ShareParams(text: url));
      messenger
          .showSnackBar(const SnackBar(content: Text('Lien copié et partagé')));
    } catch (e) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Lien de partage indisponible')));
    }
  }

  Future<void> _exportQrImageAndShare(String svgQrCode) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _captureQrAsPngFile();
      await SharePlus.instance
          .share(ShareParams(files: [XFile(file.path)], text: 'Ma carte KART'));
      messenger.showSnackBar(const SnackBar(content: Text('Image partagée')));
    } catch (e) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Impossible d\'exporter l\'image')));
    }
  }

  Future<File> _captureQrAsPngFile() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('QR widget not available');

    // Capture at higher pixel ratio for good quality
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode image');

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/kart_qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Render the QR SVG securely using flutter_svg.
  /// Falls back to a graceful message if SVG parsing fails.
  Widget _buildSvgPlaceholder(String svgQrCode) {
    try {
      // Render SVG string directly — ensures the QR is exactly what the backend provided
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: (context, constraints) {
          // Stack SVG and subtle scan line (uses _scanAnimation)
          return Stack(
            children: [
              Positioned.fill(
                child: svg_pkg.SvgPicture.string(
                  svgQrCode,
                  fit: BoxFit.contain,
                  allowDrawingOutsideViewBox: true,
                ),
              ),

              // Gentle horizontal scan line that moves vertically
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      final dy = _scanAnimation.value * constraints.maxHeight;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.00),
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.00),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }),
      );
    } catch (e) {
      // If SVG is invalid, show a neutral, elegant fallback
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 54,
              color: Colors.black.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 10),
            Text(
              'QR non valide',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }
}

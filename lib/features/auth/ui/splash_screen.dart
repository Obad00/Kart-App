import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Import destinations so we can use a custom animated transition
import 'login_page.dart';
import '../../navigation/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    // Fade-in du logo: 0ms -> 800ms
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Scale subtil du logo: 200ms -> 1400ms
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Glow blanc doux: commence tard et grandit progressivement
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Ligne blanche qui se trace: 1000ms -> 2000ms
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.45, 0.95, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();

    // When the splash animation completes, wait for auth initialization then navigate
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateAfterInit();
      }
    });
  }

  Future<void> _navigateAfterInit() async {
    final auth = context.read<AuthProvider>();

    // Attendre que l'auth provider ait terminé son initialisation
    await auth.waitForInit();

    // Petit délai pour une transition fluide
    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    debugPrint('🔐 Auth state after init: isAuthenticated=${auth.isAuthenticated}, user=${auth.user?.email}');

    final Widget destinationPage =
        auth.isAuthenticated ? const HomeShell() : const LoginPage();

    Navigator.of(context).pushReplacement(_createRoute(destinationPage));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper that creates a subtle, modern transition: fade + slight slide + tiny scale
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      settings: RouteSettings(name: page.runtimeType.toString()),
      transitionDuration: const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Simpler, smoother: fade in while sliding upward a tiny bit
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeInOut);
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)));
        final slide =
            Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                .animate(curved);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A1A),
              const Color(0xFF0D0D0D),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animations
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 120 + (_glowAnimation.value * 30),
                            height: 120 + (_glowAnimation.value * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(
                                      alpha: 0.15 * _glowAnimation.value),
                                  blurRadius: 30 + (_glowAnimation.value * 20),
                                  spreadRadius:
                                      10 + (_glowAnimation.value * 15),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Logo text
                      Text(
                        'KART',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4.5,
                          color: Colors.white,
                          shadows: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Animated line under logo
              FadeTransition(
                opacity: _lineAnimation,
                child: CustomPaint(
                  painter: AnimatedLinePainter(_lineAnimation.value),
                  size: const Size(80, 2),
                ),
              ),

              const SizedBox(height: 40),

              // Subtle loading indicator (optional premium touch)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CustomPaint(
                    painter: PremiumLoaderPainter(_animationController.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter for the animated line
class AnimatedLinePainter extends CustomPainter {
  final double progress;

  AnimatedLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Ligne qui se trace progressivement
    final endX = size.width * progress;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(endX, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(AnimatedLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Premium subtle loader painter
class PremiumLoaderPainter extends CustomPainter {
  final double progress;

  PremiumLoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw subtle rotating dots instead of arc for premium feel
    final angle = progress * 2 * 3.14159;

    // Three dots rotating
    for (int i = 0; i < 3; i++) {
      final dotAngle = angle + (i * 2 * 3.14159 / 3);
      final dotX = center.dx + radius * 0.8 * math.cos(dotAngle);
      final dotY = center.dy + radius * 0.8 * math.sin(dotAngle);

      canvas.drawCircle(
        Offset(dotX, dotY),
        1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PremiumLoaderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

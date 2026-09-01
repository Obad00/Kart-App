import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

// Import destinations so we can use a custom animated transition
import 'login_page.dart';
import '../../navigation/home_shell.dart';
import '../../plans/ui/plan_selection_page.dart';

const _electricBlue = Color(0xFF3B82F6);
const _violet = Color(0xFF7C3AED);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _cardAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    // Assez long pour être vu et apprécié (le contenu réel attend de toute
    // façon la fin de l'init de l'auth avant de naviguer, donc l'allonger
    // ne retarde rien qui ne l'était pas déjà en pratique).
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3800),
      vsync: this,
    );

    // La carte KART apparaît en premier, façon "pop" doux
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Fade-in du wordmark et du tagline
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.32, 0.62, curve: Curves.easeOut),
      ),
    );

    // Glow coloré derrière la carte
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Trait ondulé qui se trace sous le wordmark
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeInOut),
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

    debugPrint(
        '🔐 Auth state after init: isAuthenticated=${auth.isAuthenticated}, user=${auth.user?.email}');

    final prefs = await SharedPreferences.getInstance();
    final pendingPlanSlug = prefs.getString('pending_plan_slug');

    if (!mounted) return;

    if (auth.isAuthenticated &&
        pendingPlanSlug != null &&
        pendingPlanSlug.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        _createRoute(const PlanSelectionPage()),
      );
      return;
    }

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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = colors.onSurface;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07070A) : colors.surface,
      body: Stack(
        children: [
          // Halos de couleur en fond — même langage visuel que la page
          // publique d'inscription événement, pour une identité cohérente.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: -80,
                    left: -60,
                    child: _blurBlob(_electricBlue, 0.25 * _glowAnimation.value, 260),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -70,
                    child: _blurBlob(_violet, 0.2 * _glowAnimation.value, 280),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // La même carte KART que sur l'écran "Ma carte" : fond
                  // noir dégradé, badge KART, flottement continu.
                  AnimatedBuilder(
                    animation: _cardAnimation,
                    builder: (context, child) {
                      final t = _cardAnimation.value;
                      return Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.85 + (0.15 * t),
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _electricBlue
                                  .withValues(alpha: 0.32 * _glowAnimation.value),
                              blurRadius: 46,
                              spreadRadius: 2,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: const _SplashKartCard(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Wordmark
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'KART',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: foreground,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Trait ondulé (accent de marque) qui se trace sous le wordmark
                  FadeTransition(
                    opacity: _lineAnimation,
                    child: AnimatedBuilder(
                      animation: _lineAnimation,
                      builder: (context, _) => CustomPaint(
                        painter: SquigglePainter(_lineAnimation.value, _electricBlue),
                        size: const Size(110, 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Le réseau qui tient dans une carte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: foreground.withValues(alpha: 0.55),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loader premium discret
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CustomPaint(
                        painter: PremiumLoaderPainter(
                            _animationController.value, foreground),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurBlob(Color color, double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

/// Reprend exactement l'habillage de [BasicQrCard] (l'écran "Ma carte" —
/// fond noir dégradé, badge KART, flottement continu) pour que le tout
/// premier écran de l'app annonce déjà la vraie carte que l'utilisateur va
/// créer, plutôt qu'un visuel générique inventé pour l'occasion. La zone qui
/// accueille normalement le QR code affiche ici le monogramme KART, aucun
/// utilisateur n'étant encore connecté à ce stade.
class _SplashKartCard extends StatefulWidget {
  const _SplashKartCard();

  @override
  State<_SplashKartCard> createState() => _SplashKartCardState();
}

class _SplashKartCardState extends State<_SplashKartCard>
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge KART — identique à celui de la vraie carte
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
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

            // Emplacement du QR sur la vraie carte : ici, le monogramme KART
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5),
                ],
              ),
              child: const Center(
                child: Text(
                  'K',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Votre carte de visite',
              style: TextStyle(
                fontFamily: 'Syne',
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'prête en quelques secondes',
              style: TextStyle(
                fontFamily: 'Syne',
                color: Colors.grey[500],
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Trait ondulé (squiggle) dessiné à la main, utilisé comme accent de marque
/// sous le wordmark — se trace progressivement selon [progress] (0..1).
class SquigglePainter extends CustomPainter {
  final double progress;
  final Color color;

  SquigglePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    const waves = 3;
    final amplitude = size.height / 2;
    final midY = size.height / 2;

    path.moveTo(0, midY);
    for (int i = 0; i < waves; i++) {
      final x1 = size.width * (i + 0.5) / waves;
      final y1 = i.isEven ? midY - amplitude : midY + amplitude;
      final x2 = size.width * (i + 1) / waves;
      path.quadraticBezierTo(x1, y1, x2, midY);
    }

    // On ne dessine que la portion du trait correspondant à `progress`
    final metrics = path.computeMetrics().first;
    final extracted = metrics.extractPath(0, metrics.length * progress);
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(SquigglePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Premium subtle loader painter
class PremiumLoaderPainter extends CustomPainter {
  final double progress;
  final Color color;

  PremiumLoaderPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
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
      oldDelegate.progress != progress || oldDelegate.color != color;
}

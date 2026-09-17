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

  // Contrôleur séparé, en boucle : _animationController ne joue qu'une
  // fois (0 → 1 puis s'arrête), donc passer directement sa valeur au
  // loader figeait les 3 points au lieu de les faire tourner.
  late final AnimationController _loaderController;

  // La grande animation façon "intro de marque" n'a de sens qu'au tout
  // premier lancement après installation. Le système d'exploitation tue le
  // process Flutter en arrière-plan bien plus souvent qu'on ne le pense
  // (Android avec l'optimisation de batterie, RAM limitée, mode debug...) —
  // à chaque fois, main() redémarre et ce splash se rejoue en entier. Sans
  // ce flag, ces 3,8s redevenaient un pur délai artificiel à chaque retour
  // dans l'app, alors que l'init de l'auth, elle, est quasi instantanée dès
  // qu'un token est déjà en cache.
  static const _hasShownIntroKey = 'has_shown_full_splash_intro';

  @override
  void initState() {
    super.initState();
    // Durée par défaut (premier lancement) — potentiellement raccourcie
    // juste avant de lancer l'animation, cf. _prepareAndStart(). Les
    // courbes ci-dessous sont des Interval(0..1) relatifs à cette durée,
    // donc la raccourcir rejoue la même chorégraphie, juste plus vite.
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

    _loaderController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat();

    // When the splash animation completes, wait for auth initialization then navigate
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateAfterInit();
      }
    });

    _prepareAndStart();
  }

  Future<void> _prepareAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShownIntro = prefs.getBool(_hasShownIntroKey) ?? false;

    if (alreadyShownIntro) {
      // Un simple flash de marque, pas toute l'intro — cf. commentaire sur
      // _hasShownIntroKey.
      _animationController.duration = const Duration(milliseconds: 900);
    } else {
      await prefs.setBool(_hasShownIntroKey, true);
    }

    if (!mounted) return;
    _animationController.forward();
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
    _loaderController.dispose();
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
    // Toujours sombre, quel que soit le thème du téléphone : c'est un
    // écran de marque (cf. visuels de référence, tous sur fond noir), pas
    // un écran de contenu qui doit suivre le mode clair.
    const foreground = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge à lanyard (cf. visuels de référence fournis) :
                  // carte sombre, trou de cordon, nom de la personne
                  // connectée, signature KART en pied.
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
                              color: _electricBlue.withValues(
                                  alpha: 0.14 * _glowAnimation.value),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: const _SplashKartCard(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Wordmark — incliné vers l'avant et resserré pour évoquer
                  // l'esprit du logo (anguleux, dynamique), en gardant du
                  // vrai texte net à toutes les tailles (le fichier du logo
                  // n'existe qu'en basse résolution, illisible en grand).
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..setEntry(0, 1, -0.18),
                      child: Text(
                        'KART',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: foreground,
                        ),
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
                        painter: SquigglePainter(
                            _lineAnimation.value, _electricBlue),
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
                      child: AnimatedBuilder(
                        animation: _loaderController,
                        builder: (context, _) => CustomPaint(
                          painter: PremiumLoaderPainter(
                              _loaderController.value, foreground),
                        ),
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
}

/// Badge à lanyard — reprend les visuels de référence fournis côté produit
/// (carte sombre, trou de cordon, nom en grand, signature de marque en
/// pied) plutôt que l'ancienne carte "QR + monogramme". Les informations
/// sont celles de KART et, si quelqu'un est déjà connecté, les siennes :
/// l'app s'ouvre sur SON badge, pas sur un visuel générique.
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
    // watch : l'init de l'auth se termine pendant l'animation du splash —
    // le badge passe alors tout seul du libellé générique au nom réel.
    final user = context.watch<AuthProvider>().user;
    final name = user == null ? 'Votre badge' : user.fullName.trim();
    final role = user?.company?.name ?? 'Identité professionnelle digitale';

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attache du cordon, au-dessus de la carte.
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2.5,
              ),
            ),
          ),
          Container(
            width: 3,
            height: 10,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          Container(
            width: 250,
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF17171A), Color(0xFF070708)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trou du cordon, comme sur un vrai badge.
                Center(
                  child: Container(
                    width: 46,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                // Courbe d'accent — l'équivalent sobre du motif chromé des
                // visuels de référence, dessiné plutôt qu'importé (aucun
                // asset haute résolution disponible).
                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: CustomPaint(painter: _BadgeSwirlPainter()),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _electricBlue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'K',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 12,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'KART',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Deux boucles entrelacées façon ruban métallique (cf. visuels fournis) —
/// un dégradé clair sur trait épais suffit à en donner l'impression sans
/// image bitmap.
class _BadgeSwirlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFE9EDF2), Color(0xFF7E8894), Color(0xFFD6DCE4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.78)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.08,
        size.width * 0.46,
        size.height * 0.06,
        size.width * 0.44,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.43,
        size.height * 1.06,
        size.width * 0.74,
        size.height * 0.98,
        size.width * 0.72,
        size.height * 0.36,
      )
      ..cubicTo(
        size.width * 0.71,
        size.height * 0.02,
        size.width * 0.94,
        size.height * 0.12,
        size.width * 0.96,
        size.height * 0.54,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BadgeSwirlPainter oldDelegate) => false;
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

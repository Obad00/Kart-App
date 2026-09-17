import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

// Import destinations so we can use a custom animated transition
import 'login_page.dart';
import '../../navigation/home_shell.dart';
import '../../plans/ui/plan_selection_page.dart';

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
    // La CARTE reste noire dans les deux modes — c'est l'objet KART
    // lui-même (cf. visuel de référence) — mais la scène autour suit le
    // thème du téléphone : fond clair et texte sombre en mode clair.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? Colors.white : const Color(0xFF0B0B0F);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF07070A) : const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          SafeArea(
            // FittedBox(scaleDown) : sur un écran court (fenêtre web
            // redimensionnée, petit téléphone en paysage), la colonne
            // cordon + carte + wordmark + tagline dépassait la hauteur
            // disponible et déclenchait un RenderFlex overflow. Elle se
            // réduit proportionnellement au lieu d'être coupée — même
            // parade que la card JobMatch. mainAxisSize.min est
            // indispensable ici : sans lui, la colonne réclame une hauteur
            // infinie dans le FittedBox.
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Carte KART suspendue à son cordon (cf. visuel de
                      // référence fourni) : carte noire mate, marque en haut à
                      // droite, nom de la personne connectée en bas à gauche.
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
                          builder: (context, child) => Opacity(
                            // Simple montée en présence : le halo bleu d'avant
                            // dessinait un bloc coloré derrière le cordon, à
                            // l'opposé du visuel de référence (noir intégral).
                            opacity: 0.35 + (0.65 * _glowAnimation.value),
                            child: child,
                          ),
                          child: _SplashKartCard(isDark: isDark),
                        ),
                      ),

                      // Ni wordmark ni trait décoratif sous la carte : le
                      // nom de la marque est déjà sur la carte ET sur le
                      // cordon, le réécrire en grand juste en dessous
                      // faisait triplon et éloignait du visuel de
                      // référence, qui ne montre que le porte-badge.
                      const SizedBox(height: 34),

                      FadeTransition(
                        opacity: _fadeAnimation,
                        // Largeur bornée : c'est l'élément le plus large de
                        // la colonne, donc celui qui pilote la réduction du
                        // FittedBox — sans borne, il touche les deux bords
                        // sur un téléphone étroit.
                        child: SizedBox(
                          width: 250,
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte KART suspendue à son cordon — reprend le visuel de référence
/// fourni côté produit : carte noire mate, marque en haut à droite, nom en
/// bas à gauche, arcs discrets dans l'angle. Les informations sont celles
/// de KART et, si quelqu'un est déjà connecté, les siennes : l'app s'ouvre
/// sur SA carte, pas sur un visuel générique.
class _SplashKartCard extends StatefulWidget {
  /// Le thème n'change pas la carte elle-même (toujours noire) : il sert
  /// uniquement à poser une ombre portée en mode clair, sans laquelle la
  /// carte paraît découpée sur le fond clair.
  final bool isDark;

  const _SplashKartCard({required this.isDark});

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
    // la carte passe alors d'elle-même du libellé KART au nom réel.
    final user = context.watch<AuthProvider>().user;

    final title = user == null ? 'KART' : user.fullName.trim().toUpperCase();
    final subtitle = user?.company?.name.toUpperCase() ??
        'IDENTITÉ PROFESSIONNELLE DIGITALE';
    final footer = user == null
        ? 'PRÊTE EN QUELQUES SECONDES'
        : 'ID ${user.id.toString().padLeft(10, '0')}';

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LanyardStrap(),
          Container(
            width: 236,
            height: 342,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF121214), Color(0xFF050506)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              // Deux ombres superposées : une large et très diffuse pour
              // la profondeur, une courte au contact. Une seule ombre
              // marquée dessinait une barre grise nette sous la carte
              // plutôt qu'une ombre portée.
              boxShadow: widget.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 44,
                        spreadRadius: -6,
                        offset: const Offset(0, 22),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        spreadRadius: -4,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Arcs concentriques dans l'angle bas-droit, très peu
                // contrastés — la texture du visuel de référence.
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(painter: const _CornerArcsPainter()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38,
                        child: Stack(
                          children: [
                            // Perforation, alignée sous l'anneau du cordon.
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF040405),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                              ),
                            ),
                            const Align(
                              alignment: Alignment.topRight,
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: CustomPaint(painter: _KartMarkPainter()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Syne',
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        // 2 lignes : "IDENTITÉ PROFESSIONNELLE DIGITALE"
                        // ne tient pas sur une seule à cet interlettrage et
                        // ressortait tronqué ("PROFESSIONNELL…").
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 9.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        footer,
                        style: TextStyle(
                          fontFamily: 'Syne',
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cordon + mousqueton au-dessus de la carte, avec le nom de la marque
/// répété dessus comme sur le visuel de référence.
class _LanyardStrap extends StatelessWidget {
  const _LanyardStrap();

  @override
  Widget build(BuildContext context) {
    // Le cordon et l'attache restent sombres (ils font partie de l'objet),
    // mais l'anneau se détache sur le FOND de la page : en blanc translucide
    // il devenait invisible en mode clair.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.28);

    return SizedBox(
      height: 202,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Sangle large, comme sur le visuel de référence : le nom de la
          // marque y est répété verticalement, chaque occurrence tournée,
          // et la sangle est volontairement coupée en haut — elle doit se
          // lire comme un cordon qui sort du cadre, pas comme une étiquette.
          Container(
            width: 46,
            // Hauteur calée sur les 3 occurrences tournées de "KART" :
            // trop courte, la Column débordait (RenderFlex overflow).
            height: 172,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF131316), Color(0xFF0A0A0C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.symmetric(
                vertical: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                3,
                (_) => RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'KART',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.62),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Attache métallique puis anneau, comme sur le visuel.
          Container(
            width: 26,
            height: 13,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2A2E), Color(0xFF131316)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marque KART : disque rayé, écho du logo du visuel de référence (barres
/// blanches de largeurs inégales détourées en cercle).
class _KartMarkPainter extends CustomPainter {
  const _KartMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Offset.zero & size));

    final paint = Paint()..color = Colors.white;
    // Barres de hauteur constante, largeurs décalées : donne le relief du
    // logo sans dépendre d'un asset (aucun fichier haute résolution
    // disponible côté projet).
    const bars = 7;
    final barHeight = size.height / (bars * 1.85);
    for (var i = 0; i < bars; i++) {
      final top = size.height * (i + 0.5) / bars - barHeight / 2;
      final inset = size.width * (i.isEven ? 0.06 : 0.18) * (i / bars + 0.35);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, top, size.width - inset * 2, barHeight),
        Radius.circular(barHeight),
      );
      canvas.drawRRect(rect, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_KartMarkPainter oldDelegate) => false;
}

/// Arcs concentriques très discrets dans l'angle bas-droit de la carte.
class _CornerArcsPainter extends CustomPainter {
  const _CornerArcsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.white.withValues(alpha: 0.045);

    final center = Offset(size.width * 1.1, size.height * 1.12);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, size.width * 0.13 * i, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerArcsPainter oldDelegate) => false;
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

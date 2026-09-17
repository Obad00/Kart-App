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
                          // Entrée : le porte-badge DESCEND et se pose au
                          // bout de son cordon (la courbe easeOutBack du
                          // contrôleur donne le petit rebond d'arrivée),
                          // au lieu d'un simple grossissement sur place.
                          final t = _cardAnimation.value;
                          return Opacity(
                            opacity: t.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, -46 * (1 - t)),
                              child: Transform.scale(
                                scale: 0.94 + (0.06 * t),
                                child: child,
                              ),
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

// Géométrie de l'attache, partagée entre la carte et l'anneau pour qu'ils
// restent concentriques quoi qu'il arrive.
const double _cardTopInset = 11;
const double _holeSize = 13;
const double _ringSize = 23;
const double _holeCenterY = _cardTopInset + 10;

class _SplashKartCardState extends State<_SplashKartCard>
    with TickerProviderStateMixin {
  // Balancement : un badge pendu à un cordon oscille autour de son anneau.
  // Remplace l'ancien flottement vertical, qui faisait léviter la carte
  // sans rapport avec l'objet.
  late final AnimationController _swingController;
  late final Animation<double> _swingAnimation;

  // Reflet qui balaie la surface — la carte est noire brillante sur le
  // visuel de référence ; sans ce passage de lumière elle paraît éteinte.
  late final AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _swingAnimation = Tween<double>(begin: -0.028, end: 0.028).animate(
      CurvedAnimation(parent: _swingController, curve: Curves.easeInOutSine),
    );

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(period: const Duration(milliseconds: 5200));
  }

  @override
  void dispose() {
    _swingController.dispose();
    _sheenController.dispose();
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
      animation: _swingAnimation,
      // alignment.topCenter : la rotation se fait autour de l'attache,
      // comme un vrai badge au bout de son cordon.
      builder: (context, child) => Transform.rotate(
        angle: _swingAnimation.value,
        alignment: Alignment.topCenter,
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LanyardStrap(),
          // Stack (et non Column) : sur le visuel de référence l'anneau
          // TRAVERSE la perforation, il est donc à cheval sur le bord
          // supérieur de la carte, pas posé au-dessus.
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: _cardTopInset),
                width: 236,
                height: 342,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF121214), Color(0xFF050506)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedBuilder(
                          animation: _sheenController,
                          builder: (context, _) => CustomPaint(
                            painter: _SheenPainter(_sheenController.value),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // La perforation n'est plus ici : elle est
                          // positionnée au bord haut de la carte, avec
                          // l'anneau exactement par-dessus (cf. plus bas).
                          const Align(
                            alignment: Alignment.topRight,
                            child: _KartMark(),
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
              // Perforation de la carte, puis anneau EXACTEMENT centré
              // dessus : c'est ce qui donne l'impression que l'anneau
              // traverse le trou, au lieu d'être posé au-dessus.
              // _holeCenterY est partagé par les deux, il ne peut donc pas
              // y avoir de décalage.
              Positioned(
                top: _holeCenterY - _holeSize / 2,
                child: Container(
                  width: _holeSize,
                  height: _holeSize,
                  decoration: const BoxDecoration(
                    color: Color(0xFF020203),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: _holeCenterY - _ringSize / 2,
                child: Container(
                  width: _ringSize,
                  height: _ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.55),
                      width: 2.4,
                    ),
                  ),
                ),
              ),
            ],
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
    return Column(
      // AUCUNE hauteur fixe ici, et mainAxisSize.min : la sangle est
      // dimensionnée PAR son texte. Une hauteur en dur calée à la main
      // débordait dès que la police réelle (Syne) rendait les libellés
      // tournés plus hauts que dans mes essais — RenderFlex overflow
      // visible sur l'appareil mais pas en test, faute de la vraie police.
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
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
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              2,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: RotatedBox(
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
        ),
        // Mousqueton : le corps métallique, puis la tige qui descend vers
        // l'anneau (lequel traverse la perforation, cf. _SplashKartCard).
        Container(
          width: 28,
          height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E2E33), Color(0xFF141417)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        Container(
          width: 5,
          height: 9,
          color: const Color(0xFF232327),
        ),
      ],
    );
  }
}

/// Marque KART en haut à droite de la carte : le "K" de la marque dans sa
/// pastille, à la place du disque rayé du visuel de référence (qui est le
/// logo d'une autre marque).
class _KartMark extends StatelessWidget {
  const _KartMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'K',
        style: TextStyle(
          fontFamily: 'Syne',
          fontSize: 22,
          height: 1,
          fontWeight: FontWeight.w800,
          color: Color(0xFF07070A),
        ),
      ),
    );
  }
}

/// Reflet diagonal qui traverse la carte, puis disparaît jusqu'au passage
/// suivant. Donne à la surface noire l'aspect brillant du visuel de
/// référence — sans lui, la carte paraît complètement éteinte à l'écran.
class _SheenPainter extends CustomPainter {
  /// 0 → 1 sur la durée d'un passage.
  final double progress;

  const _SheenPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // La bande part hors cadre à gauche et sort à droite : la largeur
    // parcourue vaut donc deux fois celle de la carte.
    final travel = size.width * 2;
    final x = -size.width * 0.5 + travel * progress;

    // Atténuation aux extrémités : le reflet naît et meurt en douceur au
    // lieu d'apparaître d'un bloc au bord de la carte.
    final fade = (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
    if (fade <= 0) return;

    canvas.save();
    // Bande inclinée, comme une lumière rasante.
    canvas.translate(x, 0);
    canvas.rotate(-0.38);

    final bandWidth = size.width * 0.42;
    final rect = Rect.fromLTWH(
      -bandWidth / 2,
      -size.height,
      bandWidth,
      size.height * 3,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.07 * fade),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter oldDelegate) =>
      oldDelegate.progress != progress;
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

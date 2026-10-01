import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_svg/flutter_svg.dart' as svg_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/onboarding/onboarding_prefs.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../../../shared/widgets/coming_soon_sheet.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../../shared/utils/initials.dart';
import '../../auth/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/card_provider.dart';
import '../../contacts/providers/highlight_provider.dart';
import '../../contacts/widgets/highlight_bar.dart';
import '../../profile_completion/ui/completion_form_page.dart';

// widgets
import '../widgets/card_header.dart';
import '../widgets/card_quick_actions.dart';
import '../widgets/card_stats_row.dart';
import '../widgets/kart_card_data.dart';
import '../widgets/kart_card_faces.dart';
import '../widgets/kart_flip_card.dart';
import '../widgets/no_card_cta.dart';
import '../widgets/card_error_state.dart';
import 'create_card_page.dart';
import '../../../shared/widgets/qr_fullscreen_view.dart';
import '../../scan/ui/scan_page.dart';

class MyDigitalCardPage extends StatefulWidget {
  final bool minimal;
  final GlobalKey? highlightBarKey;
  final GlobalKey? createCardKey;

  /// true quand la page est déjà montée sous le Scaffold d'un parent
  /// (HomeShell, ScanPage) : elle ne pose alors pas son propre Scaffold,
  /// pour qu'il n'y ait qu'un seul fond/Material sur tout l'écran. false
  /// (par défaut) pour l'usage en route à part entière (MyDigitalCardGuard,
  /// route '/my-card'), qui a besoin de son propre Scaffold.
  final bool embedded;

  const MyDigitalCardPage({
    super.key,
    this.minimal = false,
    this.highlightBarKey,
    this.createCardKey,
    this.embedded = false,
  });

  @override
  State<MyDigitalCardPage> createState() => _MyDigitalCardPageState();
}

class _MyDigitalCardPageState extends State<MyDigitalCardPage>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  late final AnimationController _qrTapCtrl;
  late final Animation<double> _qrScale;

  final GlobalKey _qrKey = GlobalKey();
  // Capture la face QR entière (fond, logo, nom, QR...) pour le
  // téléchargement — avant, seul le QR code lui-même (_qrKey) était exporté.
  final GlobalKey _fullCardKey = GlobalKey();

  // Retournement de la carte : 0 = face QR (par défaut), 1 = face infos.
  // Partagé par la carte, le bouton sous la carte et les points.
  late final AnimationController _flipCtrl;
  late final Animation<double> _flip;

  // Repli si aucune clé externe n'est fournie (ex: mode minimal) — le
  // Showcase se comporte alors comme un simple wrapper transparent, sans
  // effet visuel tant que startShowCase() ne cible pas cette clé.
  late final GlobalKey _highlightBarKeyInternal =
      widget.highlightBarKey ?? GlobalKey();
  late final GlobalKey _createCardKeyInternal =
      widget.createCardKey ?? GlobalKey();

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cardProvider = context.read<CardProvider>();
      final highlightProvider = context.read<HighlightProvider>();

      // idle : rien n'a encore été déclenché, on s'en charge nous-mêmes
      // (comportement historique). loading : le splash a déjà démarré ce
      // chargement en arrière-plan pendant sa propre animation (cf.
      // SplashScreen._preloadHomeData()) — on attend juste sa résolution
      // au lieu de relancer un second appel par-dessus, remonté côté
      // produit : "Ma carte" ne devrait pas re-charger ce que le splash a
      // déjà préchauffé.
      if (cardProvider.status == CardStatus.idle) {
        await cardProvider.loadCardSummary();
      } else if (cardProvider.status == CardStatus.loading) {
        await _waitForCardStatusSettled(cardProvider);
      }

      if (!mounted) return;

      if (cardProvider.status == CardStatus.hasCard) {
        if (!cardProvider.hasQrCode) {
          await cardProvider.loadMyCardQr();
        }
        // Sans await : le bloc statistiques apparaît quand il arrive, il ne
        // retarde ni les highlights ni le popup poste/entreprise.
        if (!widget.minimal) cardProvider.loadWeeklyStats();
        if (highlightProvider.highlights.isEmpty &&
            !highlightProvider.isLoading) {
          await highlightProvider.loadHighlights();
        }
        await _maybePromptJobCompany(cardProvider);
      }
    });
  }

  Future<void> _waitForCardStatusSettled(CardProvider provider) {
    if (provider.status != CardStatus.loading) return Future.value();

    final completer = Completer<void>();
    void listener() {
      if (provider.status != CardStatus.loading) {
        provider.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    }

    provider.addListener(listener);
    return completer.future;
  }

  /// Popup "Complétez poste & entreprise" — affiché une seule fois, quelques
  /// secondes après l'arrivée sur cet écran, seulement pour un compte dont
  /// la carte vient d'être créée automatiquement à l'inscription (cf.
  /// EmailVerificationPage) et qui n'a encore ni poste ni entreprise.
  Future<void> _maybePromptJobCompany(CardProvider cardProvider) async {
    final pending = await OnboardingPrefs.consumePendingJobCompanyPrompt();
    if (!pending || !mounted) return;

    final stillEmpty =
        (cardProvider.jobTitle == null || cardProvider.jobTitle!.isEmpty) &&
            (cardProvider.company == null || cardProvider.company!.isEmpty);
    if (!stillEmpty) return;

    // Laisse le temps de voir la carte apparaître avant l'interruption —
    // 3s donnait l'impression que le popup coupait l'utilisateur en plein
    // arrivée sur sa carte (QR, animation d'entrée...).
    await Future.delayed(const Duration(seconds: 6));
    if (!mounted) return;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const CompletionFormPage(section: 'basic'),
    );
  }

  void _initAnimations() {
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOutExpo,
    );

    _scale = Tween(begin: 0.92, end: 1.0).animate(_fade);

    _qrTapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _qrScale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _qrTapCtrl, curve: Curves.easeInOutCubic),
    );

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flip = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);
  }

  bool get _showingInfo => _flipCtrl.value >= 0.5;

  /// Retourne la carte (bouton sous la carte, tap sur la face qui dépasse).
  void _toggleFace() => _showFace(!_showingInfo);

  // Swipe : face de départ et distance parcourue depuis le début du geste.
  bool? _dragFromInfo;
  double _dragDistance = 0;

  // Sens et face de départ de l'échange en cours (cf. KartFlipCard) : la
  // carte de devant part dans le sens du doigt ; -1 (gauche) par défaut.
  double _swipeDirection = -1;
  bool _swapFromInfo = false;

  /// La carte suit le doigt, dans les deux sens : la progression dépend de
  /// la distance horizontale parcourue, pas de sa direction.
  void _onCardDrag(double dx, double cardWidth) {
    if (_dragFromInfo == null) {
      _dragFromInfo = _showingInfo;
      setState(() {
        _swapFromInfo = _showingInfo;
        _swipeDirection = dx > 0 ? 1 : -1;
      });
    }
    _dragDistance += dx;
    final progress = (_dragDistance.abs() / cardWidth).clamp(0.0, 1.0);
    _flipCtrl.value = _dragFromInfo! ? 1 - progress : progress;
  }

  /// Au lâcher : l'autre face si le geste est rapide ou a dépassé la
  /// moitié, sinon retour à la face de départ.
  void _onCardDragEnd(double velocity) {
    final fromInfo = _dragFromInfo ?? _showingInfo;
    _dragFromInfo = null;
    _dragDistance = 0;
    final crossed = fromInfo ? _flipCtrl.value < 0.5 : _flipCtrl.value > 0.5;
    final flipToOther = crossed || velocity.abs() > 350;
    final target = flipToOther ? !fromInfo : fromInfo;
    if (target != fromInfo) HapticFeedback.selectionClick();
    target ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  Future<void> _showFace(bool info) {
    if (info != _showingInfo) {
      setState(() {
        _swapFromInfo = _showingInfo;
        _swipeDirection = -1;
      });
    }
    HapticFeedback.selectionClick();
    return info ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _qrTapCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _reload() => context.read<CardProvider>().loadMyCardQr();

  /// Pose un Scaffold uniquement quand cette page n'est pas déjà montée
  /// sous celui d'un parent (cf. MyDigitalCardPage.embedded) — évite un
  /// second fond potentiellement différent (Scaffold.backgroundColor par
  /// défaut vs colorScheme.surface utilisé partout ailleurs) derrière la
  /// pilule de nav flottante de HomeShell.
  Widget _wrapScaffold(BuildContext context, Widget body) {
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final user = auth.user;

    final fullName = user != null
        ? '${user.firstname} ${user.lastname}'.trim()
        : 'Utilisateur';

    final initials = getInitials(fullName);


    final topInset = MediaQuery.of(context).padding.top;

    // Mode minimal (verso de ScanPage) : la carte seule, centrée, sous
    // l'en-tête de ScanPage.
    if (widget.minimal) {
      return _wrapScaffold(
        context,
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 56, bottom: 20),
            child: Center(
              child: SingleChildScrollView(
                child: _buildCardArea(user, fullName),
              ),
            ),
          ),
        ),
      );
    }

    return _wrapScaffold(
      context,
      Stack(
        children: [
          SingleChildScrollView(
            // Le contenu démarre sous la barre d'état et défile ensuite
            // derrière la bande de verre posée par-dessus (cf. plus bas).
            padding: EdgeInsets.only(
              top: topInset,
              bottom: BottomNavMetrics.bottomInset(
                      MediaQuery.of(context).padding.bottom) +
                  12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header avec menu hamburger et profil
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: CardHeader(
                    initials: initials,
                    fullName: fullName,
                    onLeadsTap: () => Navigator.pushNamed(context, '/leads'),
                  ),
                ),
                const SizedBox(height: 8),
                // Highlights (catégories) sous le header
                Showcase(
                  key: _highlightBarKeyInternal,
                  title: 'Highlights',
                  description:
                      "Créez des \"highlights\" pour regrouper vos contacts par événement (salon, conférence...).",
                  child: const HighlightBar(),
                ),
                const SizedBox(height: 20),
                _buildCardArea(user, fullName),
              ],
            ),
          ),
          // Bande de verre sous la barre d'état : même flou et même teinte
          // que GlassAppBar sur les autres onglets — le contenu y défile
          // derrière au lieu d'être coupé net.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topInset,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.32
                          : 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zone de la carte : états chargement / erreur / sans carte, puis la
  /// carte retournable avec son bouton et ses points.
  Widget _buildCardArea(User? user, String fullName) {
    return Consumer<CardProvider>(
      builder: (_, state, __) {
        if (state.hasError) {
          return SizedBox(
            height: 360,
            child: CardErrorState(
              message: state.error!,
              onRetry: _reload,
            ),
          );
        }

        if (state.status == CardStatus.noCard) {
          return SizedBox(
            height: 360,
            child: Center(
              child: Showcase(
                key: _createCardKeyInternal,
                title: 'Créez votre carte',
                description:
                    'Créez votre carte de visite digitale pour commencer à la partager.',
                child: NoCardCta(
                  onCreate: () async {
                    final navigator = Navigator.of(context);
                    final cardProvider = context.read<CardProvider>();

                    final created = await navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const CreateCardPage(),
                      ),
                    );

                    if (!mounted || created != true) return;

                    await cardProvider.loadCardSummary();
                    await cardProvider.loadMyCardQr();
                    cardProvider.loadWeeklyStats();

                    if (!mounted) return;

                    FeedbackOverlay.showSuccess(
                      context,
                      title: 'Succès',
                      subtitle: 'Carte créée avec succès 🎉',
                    );
                  },
                ),
              ),
            ),
          );
        }

        // Un seul loader pour toute cette phase (résumé ET QR),
        // pas deux successifs — isReady n'est vrai qu'une fois
        // les deux arrivés (cf. CardProvider.isReady).
        if (!state.isReady) {
          return const SizedBox(
            height: 360,
            child: Center(
              child: AppLoader(label: 'Chargement de votre carte...'),
            ),
          );
        }

        if (_fadeCtrl.value == 0) {
          _fadeCtrl.forward();
        }

        // Vérifier si l'utilisateur a une entreprise
        // On utilise les données du CardProvider (company_logo ou company_primary_color)
        // car elles viennent de /me/card-summary qui est plus fiable
        final bool hasCompanyBranding = user?.hasCompany == true ||
            (state.companyLogo != null && state.companyLogo!.isNotEmpty) ||
            (state.companyPrimaryColor != null &&
                state.companyPrimaryColor!.isNotEmpty);

        // Photo de profil en repli si aucun logo de carte n'a été
        // choisi explicitement — évite de forcer un second upload
        // pour la même chose (cf. discussion : unifier les deux
        // par défaut, tout en gardant le logo dédié prioritaire
        // pour qui veut vraiment un visuel différent).
        final String? avatarUrl =
            (user?.avatar != null && user!.avatar!.isNotEmpty)
                ? (user.avatar!.startsWith('http')
                    ? user.avatar
                    : '${ApiEndpoints.storageUrl}/${user.avatar}')
                : null;
        final bool hasPersonalLogo =
            state.logo != null && state.logo!.isNotEmpty;

        final String? logoUrl = hasCompanyBranding &&
                state.companyLogo != null &&
                state.companyLogo!.isNotEmpty
            ? state.companyLogo
            : (hasPersonalLogo ? state.logo : avatarUrl);

        final data = KartCardData(
          fullName: fullName,
          jobTitle: state.jobTitle,
          // Nom de l'entreprise à côté du logo : celui du compte entreprise,
          // sinon celui saisi sur la carte (compte individuel).
          brandName: state.company?.trim().isNotEmpty == true
              ? state.company
              : user?.company?.name,
          logoUrl: logoUrl,
          logoIsPhoto: logoUrl != null && logoUrl == avatarUrl,
          badgeLabel: hasCompanyBranding ? 'PRO' : null,
          phone: state.phone,
          email: state.email,
          city: state.city,
          // Couleur de la carte : celle de l'entreprise, sinon la couleur
          // d'accent choisie dans "Personnaliser ma carte", sinon noir mat.
          tint: CompanyColorHelper.parseHex(state.companyPrimaryColor) ??
              CompanyColorHelper.parseHex(state.accentColor),
        );

        final cardWidth =
            KartFlipCard.widthFor(MediaQuery.of(context).size.width);

        return FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              children: [
                Center(
                  child: KartFlipCard(
                    width: cardWidth,
                    animation: _flip,
                    onFlip: _toggleFace,
                    onDragUpdate: (dx) => _onCardDrag(dx, cardWidth),
                    onDragEnd: _onCardDragEnd,
                    swipeDirection: _swipeDirection,
                    swapFromInfo: _swapFromInfo,
                    qrFace: KartCardQrFace(
                      width: cardWidth,
                      data: data,
                      qr: _buildQr(state.qrSvg!),
                      captureKey: _fullCardKey,
                      // Tap sur la carte hors QR : QR en plein écran (le QR
                      // lui-même ouvre la page de scan).
                      onTapCard: () {
                        HapticFeedback.lightImpact();
                        QrFullscreenView.show(
                            context, _buildQrOnly(state.qrSvg!));
                      },
                    ),
                    infoFace: KartCardInfoFace(width: cardWidth, data: data),
                    // Faces de derrière : sans clé ni geste (évite les
                    // GlobalKey en double et les taps parasites).
                    qrFacePeek: KartCardQrFace(
                      width: cardWidth,
                      data: data,
                      qr: _buildQrOnly(state.qrSvg!),
                    ),
                    infoFacePeek:
                        KartCardInfoFace(width: cardWidth, data: data),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _flipCtrl,
                  builder: (context, _) => Column(
                    children: [
                      KartFlipButton(
                        showingInfo: _showingInfo,
                        onTap: _toggleFace,
                        progress: _flipCtrl.value,
                      ),
                      const SizedBox(height: 12),
                      KartFaceIndicator(
                        showingInfo: _showingInfo,
                        onSelect: _showFace,
                      ),
                    ],
                  ),
                ),
                // Actions rapides — absentes du mode minimal (verso de
                // ScanPage), où partager/télécharger étaient déjà désactivés.
                if (!widget.minimal) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: CardQuickActions(
                      actions: [
                        CardQuickAction(
                          icon: Icons.share_outlined,
                          label: 'Partager',
                          onTap: _shareLink,
                        ),
                        CardQuickAction(
                          icon: Icons.file_download_outlined,
                          label: 'Télécharger',
                          onTap: _exportFullCard,
                        ),
                        CardQuickAction(
                          icon: Icons.contact_page_outlined,
                          label: 'Contact',
                          onTap: _shareVcard,
                        ),
                        CardQuickAction(
                          icon: Icons.contactless_outlined,
                          label: 'NFC',
                          // Sans attendre la fermeture de la feuille : sinon
                          // le bouton afficherait un chargement derrière elle.
                          onTap: () async {
                            ComingSoonSheet.show(
                              context,
                              message:
                                  'Le partage de votre carte par NFC sera disponible dans une prochaine version de KART.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Statistiques de la semaine : affichées seulement si
                  // l'API les a renvoyées (jamais de chiffres en dur).
                  if (state.weeklyStats != null) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CardStatsRow(stats: state.weeklyStats!),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQrOnly(String svg) {
    return svg_pkg.SvgPicture.string(svg);
  }

  Widget _buildQr(String svg) {
    return GestureDetector(
      // Appui long : QR en plein écran (auparavant sur le tap de la carte,
      // masqué par le tap -> ScanPage ci-dessous).
      onLongPress: () {
        HapticFeedback.mediumImpact();
        QrFullscreenView.show(context, _buildQrOnly(svg));
      },
      onTap: () {
        _qrTapCtrl.forward().then((_) => _qrTapCtrl.reverse());

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ScanPage(),
          ),
        );
      },
      child: ScaleTransition(
        scale: _qrScale,
        child: RepaintBoundary(
          key: _qrKey,
          child: svg_pkg.SvgPicture.string(svg),
        ),
      ),
    );
  }

  /// Partage la fiche contact (.vcf) de la carte — générée par le backend
  /// (GET /cards/{slug}/vcard) : le destinataire l'ajoute à ses contacts en
  /// un geste. Réservé aux cartes publiques (404 sinon).
  Future<void> _shareVcard() async {
    final cardProvider = context.read<CardProvider>();

    try {
      // Même garde-fou que _shareLink : seul le backend connaît le slug.
      if (cardProvider.slug == null || cardProvider.slug!.isEmpty) {
        await cardProvider.loadCardSummary();
      }
      final slug = cardProvider.slug;
      if (slug == null || slug.isEmpty) {
        throw Exception(
            'Impossible de préparer votre fiche contact. Veuillez réessayer.');
      }

      final res = await ApiClient.dio.get<String>(
        '/cards/$slug/vcard',
        options: Options(responseType: ResponseType.plain),
      );

      final file = File('${(await getTemporaryDirectory()).path}/$slug.vcf');
      await file.writeAsString(res.data ?? '');

      _openShareSheet(
        ShareParams(files: [XFile(file.path, mimeType: 'text/vcard')]),
        successSubtitle: 'Fiche contact partagée',
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Erreur lors du partage de la fiche contact : $e');
      final String message;
      if (e is DioException) {
        message = e.response?.statusCode == 404
            ? 'Votre carte est privée : rendez-la publique pour partager votre fiche contact.'
            : getErrorMessage(e,
                fallback: 'Impossible de télécharger votre fiche contact.');
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Ouvre la feuille de partage sans attendre sa fermeture : le bouton
  /// d'action arrête son chargement dès que la feuille s'affiche (sinon le
  /// spinner restait visible tant que la feuille était ouverte, voire après
  /// sa fermeture). Le message de succès s'affiche quand même au retour.
  void _openShareSheet(ShareParams params, {String? successSubtitle}) {
    SharePlus.instance.share(params).then((result) {
      if (!mounted || successSubtitle == null) return;
      if (result.status == ShareResultStatus.success) {
        FeedbackOverlay.showSuccess(
          context,
          title: 'Succès',
          subtitle: successSubtitle,
        );
      }
    }).catchError((Object e) {
      debugPrint('❌ Erreur de la feuille de partage : $e');
    });
  }

  Future<void> _shareLink() async {
    final cardProvider = context.read<CardProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    try {
      // Si les donnees de la carte (slug / share_url) ne sont pas encore
      // chargees, on les recharge avant de partager : on ne doit jamais
      // deviner un lien a partir du nom, seul le backend connait le vrai slug.
      if ((cardProvider.shareUrl == null || cardProvider.shareUrl!.isEmpty) &&
          (cardProvider.slug == null || cardProvider.slug!.isEmpty)) {
        await cardProvider.loadCardSummary();
      }

      if (!mounted) return;

      String? url;

      debugPrint('🔗 Starting share process...');
      debugPrint('🔗 ShareUrl from provider: ${cardProvider.shareUrl}');
      debugPrint('🔗 Slug from provider: ${cardProvider.slug}');
      debugPrint('🔗 User: ${user?.firstname} ${user?.lastname}');

      // 1. Essayer d'utiliser l'URL de partage du CardProvider
      if (cardProvider.shareUrl != null && cardProvider.shareUrl!.isNotEmpty) {
        url = cardProvider.shareUrl;
        debugPrint('✅ Using shareUrl from provider: $url');
      }
      // 2. Sinon, essayer de generer l'URL avec le slug
      else if (cardProvider.slug != null && cardProvider.slug!.isNotEmpty) {
        url = 'https://kart.business/card/${cardProvider.slug}';
        debugPrint('✅ Generated URL with slug: $url');
      }

      if (!mounted) return;

      final fullName = user != null
          ? '${user.firstname} ${user.lastname}'.trim()
          : 'Utilisateur';

      if (url == null || url.isEmpty) {
        throw Exception(
            'Impossible de générer le lien de partage. Veuillez réessayer.');
      }

      debugPrint('✅ Opening native share sheet with URL: $url');

      final buffer = StringBuffer()
        ..write('Bonjour ! Voici ma carte de visite digitale.');
      if (cardProvider.jobTitle != null || cardProvider.company != null) {
        buffer.write('\n\n$fullName');
        if (cardProvider.jobTitle != null) {
          buffer.write(' - ${cardProvider.jobTitle}');
        }
        if (cardProvider.company != null) {
          buffer.write(' @ ${cardProvider.company}');
        }
      }
      buffer.write('\n\n$url');

      _openShareSheet(ShareParams(text: buffer.toString()));
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('❌ Erreur lors du partage : $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur lors du partage: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Exporte la face QR entière (fond, logo, nom, poste, QR...) — avant,
  /// seul le QR code isolé était exporté.
  Future<void> _exportFullCard() async {
    // Toujours la face QR : si la face infos est affichée, on retourne la
    // carte d'abord. Deux endOfFrame : le premier laisse la face QR se
    // peindre, le second garantit qu'elle est bien affichée avant de lire
    // le RenderRepaintBoundary.
    if (_flipCtrl.value > 0) await _showFace(false);
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;

    try {
      final boundary = _fullCardKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);

      final file = File(
        '${(await getTemporaryDirectory()).path}/carte-kart.png',
      )..writeAsBytesSync(
          data!.buffer.asUint8List(),
        );

      // Confirmation explicite plutôt que rien — sans ça, aucun retour ne
      // permettait de savoir si le téléchargement/partage avait réellement
      // abouti (ex: enregistré dans Photos) ou avait été fermé sans suite.
      _openShareSheet(
        ShareParams(files: [XFile(file.path)]),
        successSubtitle: 'Carte téléchargée avec succès',
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Erreur lors de l\'export de la carte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur lors du téléchargement: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/card_provider.dart';
import '../../contacts/providers/highlight_provider.dart';
import '../../contacts/widgets/highlight_bar.dart';

// widgets
import '../widgets/card_header.dart';
import '../widgets/company_qr_card.dart';
import '../widgets/basic_qr_card.dart';
import '../widgets/no_card_cta.dart';
import '../widgets/card_error_state.dart';
import '../widgets/share_bottom_sheet.dart';
import 'create_card_page.dart';
import '../../../shared/widgets/qr_fullscreen_view.dart';



class MyDigitalCardPage extends StatefulWidget {
  const MyDigitalCardPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _initAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cardProvider = context.read<CardProvider>();
      final highlightProvider = context.read<HighlightProvider>();

      await cardProvider.loadCardSummary();

      if (cardProvider.status == CardStatus.hasCard) {
        await cardProvider.loadMyCardQr();
        await highlightProvider.loadHighlights();
      }
    });
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
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _qrTapCtrl.dispose();
    super.dispose();
  }

  void _reload() => context.read<CardProvider>().loadMyCardQr();

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final card = context.watch<CardProvider>();

    final user = auth.user;

    final fullName = user != null
        ? '${user.firstname} ${user.lastname}'.trim()
        : 'Utilisateur';

    final initials = _initials(fullName);

    final subtitle = card.company?.isNotEmpty == true
        ? card.company!
        : card.jobTitle?.isNotEmpty == true
            ? card.jobTitle!
            : 'Membre';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Header avec menu hamburger et profil
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: CardHeader(
                initials: initials,
                fullName: fullName,
                subtitle: subtitle,
                onLeadsTap: () => Navigator.pushNamed(context, '/leads'),
              ),
            ),

            // Highlights - remontes juste sous le header
            const Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: HighlightBar(),
            ),

            // QR Card centrée verticalement
            Positioned(
              top: 160,
              left: 0,
              right: 0,
              bottom: 20,
              child: Consumer<CardProvider>(
                builder: (_, state, __) {
                  if (state.hasError) {
                    return CardErrorState(
                      message: state.error!,
                      onRetry: _reload,
                    );
                  }

                  if (!state.isReady &&
                      state.status != CardStatus.noCard) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (state.status == CardStatus.noCard) {
                    return Center(
                      child: NoCardCta(
                        onCreate: () async {
                          final navigator = Navigator.of(context);
                          final messenger =
                              ScaffoldMessenger.of(context);
                          final cardProvider =
                              context.read<CardProvider>();

                          final created = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CreateCardPage(),
                            ),
                          );

                          if (!mounted || created != true) return;

                          await cardProvider.loadCardSummary();
                          await cardProvider.loadMyCardQr();

                          if (!mounted) return;

                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                behavior:
                                    SnackBarBehavior.floating,
                                backgroundColor:
                                    const Color(0xFF0A0A0A),
                                elevation: 0,
                                duration:
                                    const Duration(seconds: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Carte créée avec succès 🎉',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                        },
                      ),
                    );
                  }

                  if (!state.hasQrCode) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (_fadeCtrl.value == 0) {
                    _fadeCtrl.forward();
                  }

                  // QR Widget
                  final Widget qrWidget =
                      _buildQr(state.qrSvg!);

                  void share() => _shareLink();
                  void download() =>
                      _exportQr(state.qrSvg!);

                  // Vérifier si l'utilisateur a une entreprise
                  // On utilise les données du CardProvider (company_logo ou company_primary_color)
                  // car elles viennent de /me/card-summary qui est plus fiable
                  final bool isCompanyUser = user?.hasCompany == true ||
                      (state.companyLogo != null && state.companyLogo!.isNotEmpty) ||
                      (state.companyPrimaryColor != null && state.companyPrimaryColor!.isNotEmpty);

                  return FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Center(
                        child: isCompanyUser
                            // Carte Premium pour les utilisateurs Entreprise
                            ? CompanyQrCard(
                                qrCode: qrWidget,
                                companyName: state.company ?? user?.company?.name ?? 'Entreprise',
                                companyLogo: state.companyLogo,
                                primaryColor: _parseColor(
                                  state.companyPrimaryColor,
                                  const Color(0xFF3B82F6),
                                ),
                                subtitle: state.jobTitle,
                                onShare: share,
                                onDownload: download,
                                onTapQr: () {
                                  QrFullscreenView.show(
                                    context,
                                    _buildQrOnly(state.qrSvg!),
                                  );
                                },
                              )
                            // Carte Basique pour les utilisateurs Freemium
                            : BasicQrCard(
                                qrCode: qrWidget,
                                userName: fullName,
                                jobTitle: state.jobTitle,
                                onShare: share,
                                onDownload: download,
                                onTapQr: () {
                                  QrFullscreenView.show(
                                    context,
                                    _buildQrOnly(state.qrSvg!),
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildQrOnly(String svg) {
  return svg_pkg.SvgPicture.string(svg);
}

  Color _parseColor(String? hexColor, Color fallback) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      String hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

 Widget _buildQr(String svg) {
  return GestureDetector(
    onTap: () {
      _qrTapCtrl.forward().then((_) => _qrTapCtrl.reverse());

      // Show fullscreen QR instead of navigating to switcher page
      QrFullscreenView.show(
        context,
        _buildQrOnly(svg),
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

  Future<void> _shareLink() async {
    final cardProvider = context.read<CardProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    try {
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
      // 3. Dernier recours: generer le slug a partir du nom
      else if (user != null) {
        final generatedSlug = _generateSlug(user.firstname, user.lastname);
        url = 'https://kart.business/card/$generatedSlug';
        debugPrint('✅ Generated URL from name: $url');
      }

      if (!mounted) return;

      final fullName = user != null
          ? '${user.firstname} ${user.lastname}'.trim()
          : 'Utilisateur';

      if (url == null || url.isEmpty) {
        throw Exception('Impossible de générer le lien de partage. Veuillez réessayer.');
      }

      debugPrint('✅ Opening share sheet with URL: $url');

      await ShareBottomSheet.show(
        context,
        shareUrl: url,
        userName: fullName,
        jobTitle: cardProvider.jobTitle,
        company: cardProvider.company,
      );
    } catch (e, stack) {
      if (!mounted) return;
      debugPrint('❌ Erreur lors du partage : $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Genere un slug a partir du prenom et nom
  String _generateSlug(String firstname, String lastname) {
    final slug = '${firstname.toLowerCase()}-${lastname.toLowerCase()}'
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-');
    return slug;
  }

  Future<void> _exportQr(String _) async {
    final boundary = _qrKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final image =
        await boundary.toImage(pixelRatio: 3);
    final data =
        await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(
      '${(await getTemporaryDirectory()).path}/qr.png',
    )..writeAsBytesSync(
        data!.buffer.asUint8List(),
      );

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
  }
}

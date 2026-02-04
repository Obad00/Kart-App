import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg_pkg;

import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/card_service.dart';
import '../providers/card_provider.dart';
import '../../contacts/providers/highlight_provider.dart';
import '../../contacts/widgets/highlight_bar.dart';


// widgets
import '../widgets/card_header.dart';
import '../widgets/qr_card.dart';
import '../widgets/no_card_cta.dart';
import '../widgets/card_error_state.dart';
import 'create_card_page.dart';

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

  late final AnimationController _scanCtrl;
  late final Animation<double> _scan;

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
      await highlightProvider.loadHighlights(); // ✅
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

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scan = Tween(begin: -0.4, end: 1.4).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _qrTapCtrl.dispose();
    _scanCtrl.dispose();
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
        ? (user['fullname'] ??
            ('${user['firstname'] ?? ''} ${user['lastname'] ?? ''}').trim())
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
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              child: CardHeader(
                initials: initials,
                fullName: fullName,
                subtitle: subtitle,
              ),
            ),

        // 👇 HIGHLIGHTS
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: const HighlightBar(),
                ),
                
            Padding(
              padding: const EdgeInsets.only(top: 220),
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
                    return const CircularProgressIndicator();
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
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF0A0A0A),
                            elevation: 0,
                            duration: const Duration(seconds: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Carte créée avec succès 🎉',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
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
                    return const CircularProgressIndicator();
                  }

                  if (!_fadeCtrl.isAnimating &&
                      _fadeCtrl.value == 0) {
                    _fadeCtrl.forward();
                  }

                  return FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: QrCard(
                        qr: _buildQr(state.qrSvg!),
                        onShare: _shareLink,
                        onDownload: () =>
                            _exportQr(state.qrSvg!),
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

  Widget _buildQr(String svg) {
    return GestureDetector(
      onTap: () =>
          _qrTapCtrl.forward().then((_) => _qrTapCtrl.reverse()),
      child: ScaleTransition(
        scale: _qrScale,
        child: RepaintBoundary(
          key: _qrKey,
          child: Stack(
            children: [
              svg_pkg.SvgPicture.string(svg),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scan,
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _scan.value * 200),
                    child: Container(
                      height: 6,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ PARTAGE LIEN (MODERNE)
  Future<void> _shareLink() async {
    final url = await CardService.getCardShareLink();

    await Clipboard.setData(ClipboardData(text: url));

    await SharePlus.instance.share(
      ShareParams(text: url),
    );
  }

  // ✅ PARTAGE QR (MODERNE)
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

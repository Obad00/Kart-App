import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg_pkg;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/services/card_service.dart';
import '../../scan/services/event_checkin_service.dart';

/// Scan des cartes personnelles des participants par un collaborateur de
/// l'entreprise (icône visible uniquement pour eux sur
/// EventHighlightDetailPage) — distinct du scan "habituel" (carte → ajout
/// aux contacts) et du scan public/app du QR de l'événement lui-même
/// (celui-ci marque le SCANNEUR présent) : ici c'est la carte scannée qui
/// identifie qui marquer présent pour CET événement. Reste ouverte après
/// chaque scan pour enchaîner sur le participant suivant, au lieu de se
/// fermer comme ScanPage (conçue pour un scan unique).
class EventParticipantScanPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const EventParticipantScanPage({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventParticipantScanPage> createState() =>
      _EventParticipantScanPageState();
}

class _EventParticipantScanPageState extends State<EventParticipantScanPage> {
  final _service = EventCheckinService();
  final _scannerController = MobileScannerController();
  bool _isProcessing = false;
  int _checkedInCount = 0;

  // Bascule "Scanner"/"Mon QR" — remonté côté produit : le QR de check-in
  // de l'événement (celui affiché à l'accueil côté CRM, scannable par un
  // participant avec son propre téléphone) doit aussi pouvoir être montré
  // depuis l'app, pas seulement depuis un ordinateur.
  bool _showingQr = false;
  String? _eventQrSvg;
  bool _loadingQr = false;
  String? _qrError;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleMode(bool showQr) async {
    setState(() => _showingQr = showQr);
    if (showQr && _eventQrSvg == null && !_loadingQr) {
      await _loadEventQr();
    }
  }

  Future<void> _loadEventQr() async {
    setState(() {
      _loadingQr = true;
      _qrError = null;
    });
    try {
      final svg = await CardService.getEventQrCode(widget.eventId);
      if (!mounted) return;
      setState(() {
        _eventQrSvg = svg;
        _loadingQr = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _qrError = 'Impossible de charger le QR.';
        _loadingQr = false;
      });
    }
  }

  String? _extractCardSlug(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.last;
  }

  /// Un QR de badge encode ".../events/{slug}/badge/{token}" (cf.
  /// Event::badgeCheckinUrl() côté backend) — le dernier segment est alors
  /// un jeton de présence, PAS un slug de carte : envoyé tel quel à
  /// checkinByCard(), il échouait en "carte introuvable". Remonté côté
  /// produit : scanner le badge téléchargé doit marquer présent au même
  /// titre que scanner la carte de visite.
  ({String slug, String token})? _extractBadgeToken(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    // Forme attendue : .../events/{slug}/badge/{token} — 'events' se
    // trouve donc toujours exactement 2 segments avant 'badge', quel que
    // soit le préfixe de chemin du front.
    final segments = uri.pathSegments;
    final badgeIndex = segments.indexOf('badge');
    if (badgeIndex < 2 || badgeIndex + 1 >= segments.length) return null;
    if (segments[badgeIndex - 2] != 'events') return null;

    return (slug: segments[badgeIndex - 1], token: segments[badgeIndex + 1]);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    final badge = _extractBadgeToken(rawValue);
    final slug = badge == null ? _extractCardSlug(rawValue) : null;
    if (badge == null && slug == null) return;

    setState(() => _isProcessing = true);
    try {
      final result = badge != null
          ? await _service.checkinByBadge(badge.slug, badge.token)
          : await _service.checkinByCard(widget.eventId, slug!);
      if (!mounted) return;

      final name =
          (result['user'] as Map?)?['name']?.toString() ?? 'Participant';
      final alreadyPresent = result['already_present'] == true;
      // Un scan de carte peut concerner quelqu'un qui ne s'était jamais
      // inscrit : on l'accepte (il est devant vous) mais on le signale.
      final wasRegistered = result['was_registered'] != false;

      if (alreadyPresent) {
        FeedbackOverlay.showInfo(
          context,
          title: '$name était déjà présent·e',
          subtitle: 'Passez au participant suivant.',
        );
      } else {
        setState(() => _checkedInCount++);
        FeedbackOverlay.showSuccess(
          context,
          title: '$name marqué·e présent·e ✅',
          subtitle: wasRegistered
              ? '$_checkedInCount participant·e${_checkedInCount > 1 ? 's' : ''} scanné·e${_checkedInCount > 1 ? 's' : ''}.'
              : "N'était pas inscrit·e en ligne — ajouté·e à la liste.",
        );
      }
    } on EventCheckinException catch (e) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: 'Erreur', subtitle: e.message);
      }
    } catch (_) {
      if (mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Erreur',
          subtitle: 'Erreur inconnue',
        );
      }
    } finally {
      // Délai avant de ré-armer le scan : sans lui, le même QR encore dans
      // le cadre relance immédiatement un nouveau scan en boucle avant même
      // que le collaborateur ait pu retirer la carte précédente.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeChip('Scanner', Icons.qr_code_scanner_rounded, !_showingQr,
              () => _toggleMode(false)),
          _buildModeChip(
              'Mon QR', Icons.qr_code_2_rounded, _showingQr, () => _toggleMode(true)),
        ],
      ),
    );
  }

  Widget _buildModeChip(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.black : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// QR de check-in de l'événement — même contenu que celui affiché à
  /// l'accueil côté CRM (EventController::qrCode()), pour qu'un
  /// collaborateur puisse aussi le montrer directement depuis son
  /// téléphone. Carte blanche : un QR sombre sur fond sombre ne scanne pas.
  Widget _buildQrView() {
    if (_loadingQr) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_qrError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_qrError!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadEventQr,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_eventQrSvg == null) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SizedBox(
          width: 220,
          height: 220,
          child: svg_pkg.SvgPicture.string(_eventQrSvg!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_showingQr)
            _buildQrView()
          else ...[
            MobileScanner(controller: _scannerController, onDetect: _onDetect),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (!_showingQr)
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _scannerController,
                          builder: (context, state, child) {
                            final torchOn = state.torchState == TorchState.on;
                            return IconButton(
                              icon: Icon(
                                torchOn ? Icons.flash_on : Icons.flash_off,
                                color: Colors.white,
                              ),
                              onPressed: () => _scannerController.toggleTorch(),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildModeToggle(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  widget.eventName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Syne',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _showingQr
                      ? 'Les participants peuvent scanner ce QR avec leur téléphone pour confirmer leur présence'
                      : 'Scannez la carte personnelle de chaque participant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing && !_showingQr)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

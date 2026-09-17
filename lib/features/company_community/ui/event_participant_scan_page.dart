import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
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

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
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
          subtitle:
              '$_checkedInCount participant·e${_checkedInCount > 1 ? 's' : ''} scanné·e${_checkedInCount > 1 ? 's' : ''}.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
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
            ),
          ),
          Positioned(
            top: 90,
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
                  'Scannez la carte personnelle de chaque participant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

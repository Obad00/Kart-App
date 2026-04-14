import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/scan_service.dart';
import '../../card_scanner/ui/card_scanner_screen.dart';
import '../../digital_card/ui/my_digital_card_page.dart';
import '../../navigation/home_shell.dart';

import 'package:kart_app/core/ui/feedback/feedback_overlay.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

enum ScanMode { qr, myCard, physical }

class _ScanPageState extends State<ScanPage> {
  ScanMode _mode = ScanMode.qr;

  bool _isProcessing = false;

  final ScanService _service = ScanService();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    if (capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;

    if (rawValue == null) return;

    final slug = _extractSlug(rawValue);

    if (slug == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _service.scanCard(slug);

      if (!mounted) return;

      final statusCode = result['statusCode'];

      final message = result['message'];

      if (statusCode == 201) {
        _showSuccess(message);
        _goToContacts();
      } else if (statusCode == 200) {
        _showInfo(message);
        _goToContacts();
      }
    } catch (_) {
      _showError('Erreur inconnue');
    } finally {
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String? _extractSlug(String value) {
    final uri = Uri.tryParse(value);

    if (uri == null) return null;

    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  }

  void _showSuccess(String message) {
    FeedbackOverlay.showSuccess(
      context,
      title: message,
      subtitle: 'La carte a été ajoutée à vos contacts',
    );
  }

  void _showInfo(String message) {
    FeedbackOverlay.showInfo(
      context,
      title: message,
      subtitle: 'Ce contact est déjà enregistré',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToContacts() async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeShell(initialIndex: 2),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// CAMERA QR
          if (_mode == ScanMode.qr)
            MobileScanner(
              onDetect: _onDetect,
            ),

          /// MA CARTE
          if (_mode == ScanMode.myCard) const MyDigitalCardPage(minimal: true),

          /// SCAN PHYSIQUE
          if (_mode == ScanMode.physical) const CardScannerScreen(),

          /// FRAME QR
          if (_mode == ScanMode.qr)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),

          /// HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                        arguments: {'tab': 0},
                      );
                    },
                  ),
                  const Spacer(),
                  Icon(
                    Icons.flash_off,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ],
              ),
            ),
          ),

          /// TEXT INSTRUCTION
          if (_mode == ScanMode.qr)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.18,
              left: 20,
              right: 20,
              child: const Center(
                child: Text(
                  "Scanner un Code QR pour partager votre KART",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          /// BOTTOM SWITCHER
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  _button(
                    title: "Scanner",
                    active: _mode == ScanMode.qr,
                    onTap: () {
                      setState(() {
                        _mode = ScanMode.qr;
                      });
                    },
                  ),
                  _button(
                    title: "Ma KART",
                    active: _mode == ScanMode.myCard,
                    onTap: () {
                      setState(() {
                        _mode = ScanMode.myCard;
                      });
                    },
                  ),
                  _button(
                    title: "Carte physique",
                    active: _mode == ScanMode.physical,
                    onTap: () {
                      setState(() {
                        _mode = ScanMode.physical;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          /// LOADING
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            )
        ],
      ),
    );
  }

  Widget _button({
    required String title,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

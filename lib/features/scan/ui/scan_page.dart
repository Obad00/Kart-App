import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scan_service.dart';
import 'package:kart_app/core/ui/feedback/feedback_overlay.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isProcessing = false;
  final ScanService _service = ScanService();

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

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
      } else if (statusCode == 200) {
        _showInfo(message);
      }
    } on ScanException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Erreur inconnue');
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() => _isProcessing = false);
      }
    }
  }

  String? _extractSlug(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    return uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : null;
  }

  // ✅ Nouveau contact
  void _showSuccess(String message) {
    FeedbackOverlay.showSuccess(
      context,
      title: message,
      subtitle: 'La carte a été ajoutée à vos contacts',
    );
  }

  // ℹ️ Déjà existant
  void _showInfo(String message) {
    FeedbackOverlay.showInfo(
      context,
      title: message,
      subtitle: 'Ce contact est déjà enregistré',
    );
  }

  // ❌ Erreur backend
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),

          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Scanne une carte KART',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}

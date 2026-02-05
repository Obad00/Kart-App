import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/scan_service.dart';

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

  // ✅ PROTECTION ABSOLUE
  if (capture.barcodes.isEmpty) return;

  final barcode = capture.barcodes.first;
  final rawValue = barcode.rawValue;

  if (rawValue == null || rawValue.isEmpty) return;

  final slug = _extractSlug(rawValue);
  if (slug == null) return;

  setState(() => _isProcessing = true);

  try {
    await _service.scanCard(slug);

    if (!mounted) return;
    _showSuccess();
  } catch (e) {
    if (!mounted) return;
    _showError();
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}


  String? _extractSlug(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    // ex: /cards/lamine-dabo
    return uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : null;
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact ajouté avec succès ✅'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur lors du scan ❌'),
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

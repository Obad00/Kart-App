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
        _goToContacts(); // 👈 REDIRECTION
      } else if (statusCode == 200) {
        _showInfo(message);
        _goToContacts(); // 👈 REDIRECTION
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

  void _goToContacts() async {
  await Future.delayed(const Duration(milliseconds: 900));

  if (!mounted) return;

  // Navigate to home and remove all routes until root to prevent navigation errors
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/home',
    (route) => route.isFirst,
    arguments: {'tab': 2}, // 👈 Contacts
  );
}


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Scanner une carte Kart',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            onDetect: _onDetect,
          ),

          // Frame overlay for better alignment
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner brackets for visual guidance
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCorner(),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 1.5708, // 90 degrees
                      child: _buildCorner(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.rotate(
                      angle: -1.5708, // -90 degrees
                      child: _buildCorner(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 3.14159, // 180 degrees
                      child: _buildCorner(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay to darken outside the frame
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              bgColor.withValues(alpha: 0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: isDark ? Colors.white : Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alignez le code QR dans le cadre',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isProcessing)
            Container(
              color: bgColor.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: isDark ? Colors.white : Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      'Traitement en cours...',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cornerColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cornerColor, width: 4),
          left: BorderSide(color: cornerColor, width: 4),
        ),
      ),
    );
  }
}

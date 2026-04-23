import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/card_scan_provider.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({super.key});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _retakePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        context.read<CardScanProvider>().setSelectedImage(
              File(image.path),
            );
      }
    } catch (_) {}
  }

  Future<void> _scanCard() async {
    final provider = context.read<CardScanProvider>();
    final success = await provider.scanCard();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/card-scanner/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardScanProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () {
            provider.clearImage();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Aperçu',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildImagePreview(provider, isDark),
          ),
          _buildBottomActions(provider, isDark),
        ],
      ),
    );
  }

  Widget _buildImagePreview(CardScanProvider provider, bool isDark) {
    if (provider.selectedImage == null) {
      return Center(
        child: Text(
          'Aucune image sélectionnée',
          style: TextStyle(
            color: isDark ? Colors.grey : Colors.grey[600],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(
                        provider.selectedImage!.path,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        provider.selectedImage!,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
        ),

        // SCANNING OVERLAY
        if (provider.state == ScanState.scanning)
          Container(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Analyse en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extraction des informations',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ERROR
        if (provider.state == ScanState.error && provider.error != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActions(CardScanProvider provider, bool isDark) {
    final isScanning = provider.state == ScanState.scanning;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isScanning ? null : _scanCard,
                icon: isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black54,
                        ),
                      )
                    : const Icon(Icons.document_scanner_rounded),
                label: Text(isScanning ? 'Analyse...' : 'Scanner la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isScanning ? null : _retakePhoto,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reprendre la photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

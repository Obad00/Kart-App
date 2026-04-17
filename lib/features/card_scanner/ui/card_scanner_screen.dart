import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/card_scan_provider.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        context.read<CardScanProvider>().setSelectedImage(
              File(image.path),
            );

        Navigator.pushNamed(context, '/card-scanner/preview');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'accéder à l'image"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textPrimary =
        isDark ? Colors.white : Colors.black87;

    final textSecondary =
        isDark ? const Color(0xFF9CA3AF) : Colors.black54;

    final bgColor =
        isDark ? const Color(0xFF0A0A0A) : (Colors.grey[50] ?? Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      

     appBar: AppBar(
        automaticallyImplyLeading: false, // ou true si tu veux retour
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scanner une carte',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),


      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    _buildIllustration(isDark),
                    const SizedBox(height: 40),

                    _buildTitle(textPrimary),
                    const SizedBox(height: 12),

                    _buildDescription(textSecondary),

                    const SizedBox(height: 40),

                    _buildCameraButton(),
                    const SizedBox(height: 16),

                    _buildGalleryButton(isDark),

                    const SizedBox(height: 40),

                    _buildTips(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // UI PARTS
  // =========================

  Widget _buildIllustration(bool isDark) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.08),
            (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.08),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.credit_card_rounded,
            size: 72,
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.3),
          ),
          Positioned(
            right: 32,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 24,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Color color) {
    return Text(
      'Scannez une carte de visite',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildDescription(Color color) {
    return Text(
      'Prenez une photo ou sélectionnez une image\npour extraire automatiquement les informations',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 15,
      ),
    );
  }

  Widget _buildCameraButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _pickImage(ImageSource.camera),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Prendre une photo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _pickImage(ImageSource.gallery),
        icon: Icon(
          Icons.photo_library_rounded,
          color: isDark ? Colors.white : Colors.black87,
        ),
        label: Text(
          'Choisir depuis la galerie',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildTips(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Assurez-vous que la carte est bien éclairée et lisible',
              style: TextStyle(
                color: isDark
                    ? Colors.amber[100]
                    : Colors.amber[900],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

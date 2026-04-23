import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../providers/card_scan_provider.dart';

class CardScannerScreen extends StatefulWidget {
  const CardScannerScreen({super.key});

  @override
  State<CardScannerScreen> createState() => _CardScannerScreenState();
}

enum ScanMode { camera, gallery }

class _CardScannerScreenState extends State<CardScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  
  ScanMode _mode = ScanMode.camera;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

Future<void> _capturePhoto() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    return;
  }

  if (_isCapturing) return;

  setState(() => _isCapturing = true);

  try {
    final XFile image = await _cameraController!.takePicture();

    if (!mounted) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return; // ✅ IMPORTANT

    context.read<CardScanProvider>().setSelectedImage(
      File(image.path),
      bytes: bytes,
    );

    Navigator.pushNamed(context, '/card-scanner/preview');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impossible de prendre la photo"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isCapturing = false);
    }
  }
}


Future<void> _pickFromGallery() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return; // ✅ IMPORTANT

    context.read<CardScanProvider>().setSelectedImage(
      File(image.path),
      bytes: bytes,
    );

    Navigator.pushNamed(context, '/card-scanner/preview');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Impossible d'accéder à la galerie"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // CAMERA PREVIEW
          if (_mode == ScanMode.camera && _isCameraInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),

          // GALLERY VIEW (placeholder avec icône)
          if (_mode == ScanMode.gallery)
            Container(
              color: bgColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
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
                      child: Icon(
                        Icons.photo_library_rounded,
                        size: 80,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Sélectionner une photo',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choisissez une image de carte de visite\ndepuis votre galerie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Ouvrir la galerie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // FRAME pour la caméra (guide visuel)
            if (_mode == ScanMode.camera)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15, // 🔥 plus haut
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),


          // HEADER
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (_mode == ScanMode.camera)
                    Icon(
                      Icons.flash_off,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                ],
              ),
            ),
          ),

          // TEXT INSTRUCTION
          if (_mode == ScanMode.camera)
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25, // 🔥 remonté
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  "Placez la carte dans le cadre",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Assurez-vous que la carte soit bien éclairée",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // CAPTURE BUTTON (mode caméra)
         if (_mode == ScanMode.camera)
            Positioned(
              bottom: 250, // 🔥 était 160
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isCapturing ? null : _capturePhoto,
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _isCapturing
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 34,
                            color: Colors.black,
                          ),
                  ),
                ),
              ),
            ),

          // BOTTOM SWITCHER
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
                    title: "Caméra",
                    icon: Icons.camera_alt,
                    active: _mode == ScanMode.camera,
                    onTap: () {
                      setState(() {
                        _mode = ScanMode.camera;
                      });
                    },
                  ),
                  _button(
                    title: "Galerie",
                    icon: Icons.photo_library_rounded,
                    active: _mode == ScanMode.gallery,
                    onTap: () {
                      setState(() {
                        _mode = ScanMode.gallery;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // LOADING OVERLAY
          if (_isCapturing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _button({
    required String title,
    required IconData icon,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
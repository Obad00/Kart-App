import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class LogoPickerField extends StatefulWidget {
  final String label;
  final String? initialUrl;
  final ValueChanged<String?> onLogoChanged;

  const LogoPickerField({
    super.key,
    required this.label,
    this.initialUrl,
    required this.onLogoChanged,
  });

  @override
  State<LogoPickerField> createState() => _LogoPickerFieldState();
}

class _LogoPickerFieldState extends State<LogoPickerField> {
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialUrl;
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();

    // Afficher un bottom sheet pour choisir la source
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choisir une image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromSource(ImageSource.gallery);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromSource(ImageSource.camera);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _imageUrl = null;
          });
          widget.onLogoChanged(pickedFile.path);
          HapticFeedback.mediumImpact();
        } else {
          throw Exception('Fichier introuvable');
        }
      }
    } catch (e) {
      debugPrint('Erreur image picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _removeImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImage = null;
      _imageUrl = null;
    });
    widget.onLogoChanged(null);
  }

  Widget _buildPreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _selectedImage!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _imageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildPlaceholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildLoading();
          },
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 4),
          Text(
            'Logo',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  bool get _hasImage =>
      _selectedImage != null || (_imageUrl != null && _imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // Container principal
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // Aperçu du logo
              GestureDetector(
                onTap: _pickImage,
                child: _buildPreview(),
              ),

              const SizedBox(width: 20),

              // Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logo de l\'entreprise',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hasImage
                          ? 'Appuyez pour modifier'
                          : 'Format PNG ou JPG recommandé',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Boutons
                    Row(
                      children: [
                        // Bouton sélectionner
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF3B82F6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.upload_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _hasImage ? 'Modifier' : 'Choisir',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bouton supprimer
                        if (_hasImage) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

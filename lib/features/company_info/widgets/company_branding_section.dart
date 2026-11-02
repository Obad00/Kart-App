import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/logo_upload.dart';
import '../services/company_branding_service.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Logo et couleurs de l'entreprise (admin) : envoi du logo depuis la
/// galerie, puis choix des couleurs parmi celles extraites du logo
/// (modifiables, jamais appliquées d'office).
class CompanyBrandingSection extends StatefulWidget {
  final Map<String, dynamic> company;
  final VoidCallback onChanged;
  final CompanyBrandingService? service;
  final Future<String?> Function()? pickImage;

  const CompanyBrandingSection({super.key, required this.company, required this.onChanged, this.service, this.pickImage});

  @override
  State<CompanyBrandingSection> createState() => _CompanyBrandingSectionState();
}

class _CompanyBrandingSectionState extends State<CompanyBrandingSection> {
  late final CompanyBrandingService _service = widget.service ?? CompanyBrandingService();
  late List<String> _colors = _readColors(widget.company['brand_colors']);
  late String? _primary = widget.company['primary_color'] as String?;
  late String? _secondary = widget.company['secondary_color'] as String?;
  bool _uploading = false;
  bool _saving = false;

  static List<String> _readColors(Object? value) =>
      (value as List?)?.whereType<String>().take(8).toList() ?? const [];

  static Color _color(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

  Future<String?> _pick() async {
    if (widget.pickImage != null) return widget.pickImage!();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000);
    return file?.path;
  }

  Future<void> _upload() async {
    final path = await _pick();
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final branding = await _service.uploadLogo(path);
      if (!mounted) return;
      setState(() => _colors = _readColors(branding['brand_colors']));
      widget.onChanged();
      FeedbackOverlay.showSuccess(context,
          title: 'Logo mis à jour',
          subtitle: _colors.isEmpty ? 'Le logo de l\'entreprise est enregistré.' : 'Choisissez vos couleurs parmi celles du logo.');
    } on LogoTooLargeException catch (e) {
      if (mounted) FeedbackOverlay.showError(context, title: 'Logo trop lourd', subtitle: e.message);
    } catch (_) {
      if (mounted) FeedbackOverlay.showError(context, title: 'Erreur', subtitle: 'Le logo n\'a pas pu être envoyé. Réessayez.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveColors() async {
    final primary = _primary;
    if (primary == null) return;
    setState(() => _saving = true);
    try {
      await _service.saveColors(primary: primary, secondary: _secondary);
      if (!mounted) return;
      widget.onChanged();
      FeedbackOverlay.showSuccess(context, title: 'Couleurs enregistrées', subtitle: 'Elles s\'appliquent aux cartes et aux invitations de l\'entreprise.');
    } catch (_) {
      if (mounted) FeedbackOverlay.showError(context, title: 'Erreur', subtitle: 'Les couleurs n\'ont pas pu être enregistrées.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget swatches(String label, String? selected, ValueChanged<String> onPick) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final hex in _colors)
                  Semantics(
                    button: true,
                    selected: hex.toUpperCase() == selected?.toUpperCase(),
                    label: '$label $hex',
                    child: GestureDetector(
                      onTap: () => onPick(hex),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _color(hex),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hex.toUpperCase() == selected?.toUpperCase() ? _themeBlue : colors.onSurface.withValues(alpha: 0.15),
                            width: hex.toUpperCase() == selected?.toUpperCase() ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Logo et couleurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.onSurface)),
          const SizedBox(height: 4),
          Text('Le logo apparaît sur les cartes, les badges et les invitations de l\'entreprise.',
              style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _upload,
            icon: _uploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.image_outlined, size: 18),
            label: Text(_uploading ? 'Envoi…' : 'Changer le logo'),
          ),
          if (_colors.isNotEmpty) ...[
            const SizedBox(height: 16),
            swatches('Couleur principale', _primary, (hex) => setState(() => _primary = hex)),
            const SizedBox(height: 14),
            swatches('Couleur secondaire', _secondary, (hex) => setState(() => _secondary = hex)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _primary == null || _saving ? null : _saveColors,
              style: ElevatedButton.styleFrom(backgroundColor: _themeBlue, foregroundColor: Colors.white, elevation: 0),
              child: Text(_saving ? 'Enregistrement…' : 'Enregistrer les couleurs'),
            ),
          ],
        ],
      ),
    );
  }
}

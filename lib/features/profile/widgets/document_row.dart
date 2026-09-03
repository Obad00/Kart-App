import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/professional_document.dart';

/// Une ligne de la section "Documents professionnels" — icône par
/// catégorie, titre, "Établissement • Année", puis le badge "Vérifié"
/// (superadmin uniquement) ou le type de fichier (PDF/Image) sinon. Tap =
/// ouvrir le fichier ; appui long ou "⋮" = actions (voir / supprimer).
class DocumentRow extends StatelessWidget {
  final ProfessionalDocument document;
  final Color companyColor;
  final VoidCallback onDelete;

  const DocumentRow({
    super.key,
    required this.document,
    required this.companyColor,
    required this.onDelete,
  });

  IconData get _categoryIcon {
    switch (document.category) {
      case DocumentCategory.diploma:
        return Icons.school_outlined;
      case DocumentCategory.certificate:
        return Icons.workspace_premium_outlined;
      case DocumentCategory.attestation:
        return Icons.military_tech_outlined;
      case DocumentCategory.other:
        return Icons.description_outlined;
    }
  }

  String get _subtitle {
    final parts = [
      if ((document.institution ?? '').isNotEmpty) document.institution!,
      if (document.year != null) document.year.toString(),
    ];
    return parts.join(' • ');
  }

  Future<void> _openFile() async {
    final url = Uri.parse('${ApiEndpoints.storageUrl}/${document.filePath}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showActions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Voir le document'),
              onTap: () {
                Navigator.pop(sheetContext);
                _openFile();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badgeColor = document.isVerified ? Colors.green : companyColor;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openFile,
        onLongPress: () => _showActions(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: companyColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon, size: 19, color: companyColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            document.isVerified
                                ? Icons.check_circle_rounded
                                : (document.fileType == 'pdf'
                                    ? Icons.insert_drive_file_outlined
                                    : Icons.image_outlined),
                            size: 11,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            document.isVerified
                                ? 'Vérifié'
                                : (document.fileType == 'pdf'
                                    ? 'PDF'
                                    : 'Image'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showActions(context),
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: colors.onSurface.withValues(alpha: 0.4),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

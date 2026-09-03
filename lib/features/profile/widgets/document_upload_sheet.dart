import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../providers/professional_document_provider.dart';

/// Bottom sheet "Ajouter un document" — titre, établissement, année,
/// catégorie (cosmétique) et fichier (PDF/JPG/PNG, 10 Mo max côté
/// backend). Le document est créé "non vérifié" ; seul le superadmin peut
/// le vérifier depuis le CRM web.
class DocumentUploadSheet extends StatefulWidget {
  final Color companyColor;

  const DocumentUploadSheet({super.key, required this.companyColor});

  @override
  State<DocumentUploadSheet> createState() => _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends State<DocumentUploadSheet> {
  final _titleCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  static const _categories = [
    ('diploma', 'Diplôme'),
    ('attestation', 'Attestation'),
    ('certificate', 'Certificat'),
    ('other', 'Autre'),
  ];
  String _category = 'diploma';

  Uint8List? _fileBytes;
  String? _fileName;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _institutionCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // withData:true force le chargement des octets du fichier — sans ça,
    // `path` peut être nul pour un fichier choisi depuis un fournisseur
    // cloud (Drive, iCloud...) ou certains sélecteurs Android récents, et
    // le fichier semblait "choisi" côté UI sans jamais pouvoir être
    // envoyé (l'upload échouait silencieusement avec "choisissez un
    // fichier").
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final picked = result?.files.single;
    if (picked?.bytes == null) return;
    setState(() {
      _fileBytes = picked!.bytes;
      _fileName = picked.name;
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Le titre est obligatoire.');
      return;
    }
    if (_fileBytes == null) {
      setState(() => _error = 'Choisissez un fichier (PDF, JPG ou PNG).');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final institution = _institutionCtrl.text.trim();
    final error = await context.read<ProfessionalDocumentProvider>().upload(
          title: _titleCtrl.text.trim(),
          institution: institution.isEmpty ? null : institution,
          year: int.tryParse(_yearCtrl.text.trim()),
          category: _category,
          fileBytes: _fileBytes!,
          fileName: _fileName!,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.companyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: widget.companyColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Ajouter un document',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diplôme, attestation ou certificat — vérifié par notre équipe après envoi.',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            AuthTextField(
              label: 'Titre',
              controller: _titleCtrl,
              prefixIcon: Icons.title_rounded,
              hint: 'Ex: Diplôme Master Management',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Établissement',
              controller: _institutionCtrl,
              prefixIcon: Icons.business_outlined,
              hint: 'Ex: UCAD',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Année',
              controller: _yearCtrl,
              prefixIcon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
              hint: 'Ex: 2024',
            ),
            const SizedBox(height: 16),
            Text(
              'Type de document',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final active = _category == c.$1;
                return ChoiceChip(
                  label: Text(c.$2),
                  selected: active,
                  onSelected: (_) => setState(() => _category = c.$1),
                  selectedColor: widget.companyColor,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : colors.onSurface.withValues(alpha: 0.7),
                  ),
                  backgroundColor: colors.onSurface.withValues(alpha: 0.06),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _fileBytes == null
                        ? colors.onSurface.withValues(alpha: 0.15)
                        : widget.companyColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileBytes == null
                          ? Icons.upload_file_outlined
                          : Icons.check_circle_rounded,
                      color: _fileBytes == null
                          ? colors.onSurface.withValues(alpha: 0.4)
                          : widget.companyColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileName ?? 'Choisir un fichier (PDF, JPG, PNG)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _fileBytes == null
                              ? colors.onSurface.withValues(alpha: 0.5)
                              : colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Ajouter le document',
              loading: _isLoading,
              onTap: _submit,
              icon: Icons.upload_rounded,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style:
                      TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

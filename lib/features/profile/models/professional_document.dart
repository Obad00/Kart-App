/// Type de document — pilote uniquement l'icône affichée côté app.
enum DocumentCategory { diploma, certificate, attestation, other }

/// "Documents professionnels" — diplômes, attestations, certificats
/// téléversés sur le profil. Le badge "Vérifié" n'est jamais posé par
/// l'utilisateur lui-même : seul le superadmin peut le faire depuis le CRM
/// web (cf. Admin\ProfessionalDocumentManagementController côté backend).
class ProfessionalDocument {
  final int id;
  final String title;
  final String? institution;
  final int? year;
  final DocumentCategory category;
  final String filePath;
  final String fileType; // 'pdf' ou 'image'
  final bool isVerified;

  ProfessionalDocument({
    required this.id,
    required this.title,
    this.institution,
    this.year,
    required this.category,
    required this.filePath,
    required this.fileType,
    required this.isVerified,
  });

  factory ProfessionalDocument.fromJson(Map<String, dynamic> json) {
    return ProfessionalDocument(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      institution: json['institution'],
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      category: _categoryFromJson(json['category']),
      filePath: json['file_path'] ?? '',
      fileType: json['file_type'] ?? 'pdf',
      isVerified: json['is_verified'] == true,
    );
  }

  static DocumentCategory _categoryFromJson(dynamic value) {
    switch (value) {
      case 'diploma':
        return DocumentCategory.diploma;
      case 'certificate':
        return DocumentCategory.certificate;
      case 'attestation':
        return DocumentCategory.attestation;
      default:
        return DocumentCategory.other;
    }
  }
}

import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/professional_document.dart';

class ProfessionalDocumentService {
  Future<List<ProfessionalDocument>> fetch() async {
    final response = await ApiClient.dio.get('/professional-documents');
    return (response.data['data'] as List)
        .map((e) => ProfessionalDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Reçoit les octets du fichier (pas un chemin disque) : file_picker peut
  // renvoyer un `path` nul pour un fichier choisi depuis un fournisseur
  // cloud (Drive, iCloud...) ou certains sélecteurs Android récents — les
  // octets, eux, sont toujours disponibles (cf. `withData: true` côté
  // DocumentUploadSheet).
  Future<ProfessionalDocument> upload({
    required String title,
    String? institution,
    int? year,
    required String category,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      if (institution != null && institution.isNotEmpty)
        'institution': institution,
      if (year != null) 'year': year,
      'category': category,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final response = await ApiClient.dio.post(
      '/professional-documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return ProfessionalDocument.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await ApiClient.dio.delete('/professional-documents/$id');
  }
}

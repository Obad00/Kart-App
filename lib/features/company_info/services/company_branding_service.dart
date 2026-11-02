import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/utils/logo_upload.dart';

/// Branding de l'entreprise depuis l'app (admin) : logo, puis couleurs
/// proposées à partir du logo (cf. CompanyController côté backend).
class CompanyBrandingService {
  /// Envoie le logo ; renvoie le branding mis à jour (avec brand_colors).
  Future<Map<String, dynamic>> uploadLogo(String localPath) async {
    final uploadPath = await prepareLogoForUpload(localPath);
    final response = await ApiClient.dio.post(
      '/companies/branding/logo',
      data: FormData.fromMap({'logo': await MultipartFile.fromFile(uploadPath, filename: uploadPath.split('/').last)}),
      options: Options(contentType: 'multipart/form-data'),
    );
    return Map<String, dynamic>.from(response.data['branding'] as Map);
  }

  Future<Map<String, dynamic>> saveColors({required String primary, String? secondary}) async {
    final response = await ApiClient.dio.put('/companies/branding/colors', data: {
      'primary_color': primary,
      if (secondary != null) 'secondary_color': secondary,
    });
    return Map<String, dynamic>.from(response.data['branding'] as Map);
  }
}

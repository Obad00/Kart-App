import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/scanned_contact.dart';

class CardScanService {
  final Dio _dio = ApiClient.dio;

  Future<CardScanResult> scanCard(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    try {
      final response = await _dio.post(
        ApiEndpoints.scanCard,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data['success'] == true) {
        return CardScanResult(
          success: true,
          contact: ScannedContact.fromJson(
            response.data['data'],
            response.data['raw_text'],
          ),
          rawText: response.data['raw_text'],
        );
      }

      return CardScanResult(
        success: false,
        error: response.data['error'] ?? 'Erreur lors du scan',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return CardScanResult(
          success: false,
          error: e.response?.data['error'] ?? 'Aucun texte détecté dans l\'image',
        );
      } else if (e.response?.statusCode == 400) {
        return CardScanResult(
          success: false,
          error: e.response?.data['detail'] ?? 'Fichier invalide',
        );
      }
      return CardScanResult(
        success: false,
        error: 'Erreur de connexion. Vérifiez votre réseau.',
      );
    } catch (e) {
      return CardScanResult(
        success: false,
        error: 'Une erreur inattendue est survenue',
      );
    }
  }

  Future<bool> saveContact(ScannedContact contact) async {
    try {
      await _dio.post(
        ApiEndpoints.contacts,
        data: contact.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

class CardScanResult {
  final bool success;
  final ScannedContact? contact;
  final String? rawText;
  final String? error;

  CardScanResult({
    required this.success,
    this.contact,
    this.rawText,
    this.error,
  });
}

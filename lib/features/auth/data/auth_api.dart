import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class AuthApi {
  Future<Response> login(String email, String password) {
    return ApiClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Response> register(Map<String, dynamic> data) {
    return ApiClient.dio.post(
      ApiEndpoints.register,
      data: data,
    );
  }

  Future<Response> googleLogin(String googleToken) {
    return ApiClient.dio.post(
      ApiEndpoints.googleToken,
      data: {'token': googleToken},
    );
  }

  Future<Response> me() {
    return ApiClient.dio.get(ApiEndpoints.me);
  }

  Future<Response> updateProfile(Map<String, dynamic> data) {
    return ApiClient.dio.put(
      ApiEndpoints.me,
      data: data,
    );
  }

  /// Prend des bytes bruts (plutôt qu'un chemin de fichier) pour fonctionner
  /// aussi bien sur mobile que sur Flutter Web — `MultipartFile.fromFile`
  /// s'appuie sur dart:io, indisponible sur le web.
  Future<Response> updateAvatar(Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return ApiClient.dio.post(ApiEndpoints.meAvatar, data: formData);
  }

  Future<Response> deleteAvatar() {
    return ApiClient.dio.delete(ApiEndpoints.meAvatar);
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) {
    return ApiClient.dio.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
      options: Options(validateStatus: (_) => true),
    );
  }

  /// Écran "Vérifiez votre email" post-inscription — envoyé une fois à
  /// l'ouverture de l'écran, puis à nouveau sur "Renvoyer l'email".
  Future<Response> resendEmailVerification() {
    return ApiClient.dio.post(ApiEndpoints.resendEmailVerification);
  }

  Future<Response> forgotPassword(String email) {
    return ApiClient.dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
      options: Options(validateStatus: (_) => true),
    );
  }

  Future<Response> deleteAccount(String password) {
    return ApiClient.dio.delete(
      ApiEndpoints.deleteAccount,
      data: {'password': password},
      options: Options(
        // We need to handle 422/401 explicitly in provider logic.
        validateStatus: (_) => true,
      ),
    );
  }
}

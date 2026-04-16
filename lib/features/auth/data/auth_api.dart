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

  Future<Response> loginWithGoogle(String idToken) {
    return ApiClient.dio.post(
      ApiEndpoints.loginGoogle,
      data: {'id_token': idToken},
    );
  }

  Future<Response> register(Map<String, dynamic> data) {
    return ApiClient.dio.post(
      ApiEndpoints.register,
      data: data,
    );
  }

  Future<Response> me() {
    return ApiClient.dio.get(ApiEndpoints.me);
  }
}

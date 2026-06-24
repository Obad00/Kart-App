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

  Future<Response> appleLogin(
    String identityToken, {
    String? firstname,
    String? lastname,
  }) {
    return ApiClient.dio.post(
      ApiEndpoints.appleToken,
      data: {
        'token': identityToken,
        if (firstname != null && firstname.isNotEmpty) 'firstname': firstname,
        if (lastname != null && lastname.isNotEmpty) 'lastname': lastname,
      },
    );
  }

  Future<Response> deleteAccount() {
    return ApiClient.dio.post(ApiEndpoints.deleteAccount);
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
}

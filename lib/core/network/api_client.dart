import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  static const _storage = FlutterSecureStorage();

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'token');
    dio.options.headers.remove('Authorization');
  }
}

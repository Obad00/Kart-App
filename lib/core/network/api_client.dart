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

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  /// Initialize the client on app start by reading any persisted token
  /// and injecting the Authorization header if present.
  static Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'token');
    dio.options.headers.remove('Authorization');
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _tokenKey = 'auth_token';
  static bool _useSecureStorage = true;

  static Future<void> setToken(String token) async {
    try {
      if (_useSecureStorage) {
        await _storage.write(key: _tokenKey, value: token);
      }
    } catch (e) {
      debugPrint('⚠️ SecureStorage failed, using SharedPreferences: $e');
      _useSecureStorage = false;
    }

    if (!_useSecureStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }

    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static Future<String?> getToken() async {
    try {
      if (_useSecureStorage) {
        return await _storage.read(key: _tokenKey);
      }
    } catch (e) {
      debugPrint('⚠️ SecureStorage read failed, using SharedPreferences: $e');
      _useSecureStorage = false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  static Future<void> clearToken() async {
    try {
      if (_useSecureStorage) {
        await _storage.delete(key: _tokenKey);
      }
    } catch (e) {
      debugPrint('⚠️ SecureStorage delete failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    dio.options.headers.remove('Authorization');
  }
}

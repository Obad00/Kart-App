import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
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

  static bool _cacheReady = false;

  static Future<void> init() async {
    final token = await getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    await _setupOfflineCache();
  }

  /// Mode hors-ligne en lecture seule : met en cache disque toute réponse
  /// GET réussie, et la ressert automatiquement si une requête échoue
  /// (pas de réseau, timeout...) — l'utilisateur retrouve les dernières
  /// données chargées au lieu d'un écran d'erreur/vide. Les requêtes
  /// d'écriture (POST/PUT/DELETE) ne sont jamais mises en cache : elles
  /// échouent normalement hors-ligne, comme avant.
  static Future<void> _setupOfflineCache() async {
    if (_cacheReady) return;
    _cacheReady = true;

    try {
      final cacheDir = await getApplicationSupportDirectory();
      final store = FileCacheStore('${cacheDir.path}/api_cache');

      dio.interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: store,
            // 'forceCache' met en cache toute réponse GET réussie même si
            // le backend n'envoie pas d'en-têtes Cache-Control (notre API
            // Laravel n'en envoie pas) — sans ça rien ne serait mis en
            // cache du tout.
            policy: CachePolicy.forceCache,
            // Liste vide = ressert le cache sur n'importe quelle erreur
            // (pas de réseau, timeout, 5xx...), pas seulement certains
            // codes HTTP précis.
            hitCacheOnErrorExcept: const [],
            maxStale: const Duration(days: 7),
          ),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Cache hors-ligne indisponible: $e');
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

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
  static CacheStore? _cacheStore;

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
      _cacheStore = store;

      dio.interceptors.add(
        DioCacheInterceptor(
          options: CacheOptions(
            store: store,
            // IMPORTANT : 'refreshForceCache' (pas 'forceCache') — toujours
            // interroger le réseau en premier et ne se rabattre sur le
            // cache QUE si la requête échoue. 'forceCache'/'request'
            // servaient le cache directement dès qu'une entrée valide
            // existait, SANS jamais retenter le réseau tant qu'elle n'a
            // pas expiré (jusqu'à 7 jours) — donc même en ligne, et même
            // après une déconnexion/reconnexion avec un autre compte,
            // l'app resservait les anciennes données (ex: /me d'un compte
            // précédent). 'refreshForceCache' force quand même la mise en
            // cache de toute réponse réussie (notre API Laravel n'envoie
            // pas d'en-têtes Cache-Control) sans jamais la préférer au
            // réseau en priorité de lecture.
            policy: CachePolicy.refreshForceCache,
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

  /// Vide le cache hors-ligne — appelé à la déconnexion pour qu'un compte
  /// ne puisse jamais voir, même un instant, des données mises en cache
  /// par un compte précédent sur le même appareil.
  static Future<void> clearOfflineCache() async {
    try {
      await _cacheStore?.clean(priorityOrBelow: CachePriority.high);
    } catch (e) {
      debugPrint('⚠️ Impossible de vider le cache hors-ligne: $e');
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

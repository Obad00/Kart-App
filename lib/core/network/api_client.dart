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
    // Le cache hors-ligne (_setupOfflineCache) est enregistré AVANT le
    // retry ci-dessous : les interceptors Dio traitent les erreurs dans
    // l'ordre INVERSE de leur ajout (le dernier ajouté est le premier
    // servi), donc le retry — ajouté en dernier — intercepte l'erreur en
    // premier et retente sur le réseau avant que le cache ne serve une
    // réponse périmée en dernier recours.
    await _setupOfflineCache();
    dio.interceptors.add(_RetryOnServerErrorInterceptor(dio));
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

/// Retente automatiquement une requête GET qui a échoué avec une erreur
/// serveur (5xx) ou de connexion — un hébergement mutualisé (limite de
/// connexions MySQL concurrentes typique) peut renvoyer une 500 le temps
/// d'une brève contention, sans que le service soit réellement en panne :
/// sans ce filet, une simple salve de requêtes au démarrage de l'app
/// (Contacts + Profil + JobMatch + résumé de carte, quasi simultanées)
/// pouvait faire échouer certaines d'entre elles alors qu'un second essai,
/// une fraction de seconde plus tard, aurait suffi.
///
/// Seul GET est retenté (jamais POST/PUT/DELETE, pour ne jamais risquer de
/// rejouer une écriture qui aurait en fait déjà réussi côté serveur).
class _RetryOnServerErrorInterceptor extends Interceptor {
  final Dio _dio;
  static const _maxRetries = 2;
  static const _retryDelay = Duration(milliseconds: 600);

  _RetryOnServerErrorInterceptor(this._dio);

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isGet = options.method.toUpperCase() == 'GET';
    final isRetryable = (err.response?.statusCode ?? 0) >= 500 ||
        err.type == DioExceptionType.connectionError;
    final attempt = (options.extra['retryAttempt'] as int?) ?? 0;

    if (!isGet || !isRetryable || attempt >= _maxRetries) {
      return handler.next(err);
    }

    await Future.delayed(_retryDelay * (attempt + 1));

    try {
      final retryOptions = options.copyWith(
        extra: {...options.extra, 'retryAttempt': attempt + 1},
      );
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}

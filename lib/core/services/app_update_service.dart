import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Résultat d'une vérification de mise à jour disponible sur le store.
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String storeUrl;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.storeUrl,
  });
}

/// Vérifie auprès de l'App Store (iOS) ou du Play Store (Android) si une
/// version plus récente de l'app a été publiée que celle installée.
///
/// Ne lève jamais d'exception vers l'appelant : en cas d'échec (pas de
/// réseau, app pas encore publiée, format de réponse inattendu...), on
/// retourne simplement `null` pour ne jamais bloquer l'utilisateur.
class AppUpdateService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isIOS) {
        return _checkAppStore(packageInfo);
      } else if (Platform.isAndroid) {
        return _checkPlayStore(packageInfo);
      }
    } catch (e) {
      debugPrint('⚠️ Vérification de mise à jour impossible: $e');
    }
    return null;
  }

  static Future<AppUpdateInfo?> _checkAppStore(
      PackageInfo packageInfo) async {
    // Sans paramètre 'country', l'API iTunes lookup interroge le store US
    // par défaut — où traînait une fiche périmée (version 1.0.3, jamais mise
    // à jour) alors que l'app est réellement publiée/à jour côté store
    // Sénégal ('sn'). Résultat : la comparaison de version pensait que
    // l'utilisateur avait toujours la dernière version, l'alerte ne
    // s'affichait donc jamais. Fixé en interrogeant explicitement le store
    // où l'app est effectivement suivie.
    final response = await _dio.get(
      'https://itunes.apple.com/lookup',
      queryParameters: {
        'bundleId': packageInfo.packageName,
        'country': 'sn',
      },
    );

    final results = response.data?['results'];
    if (results is! List || results.isEmpty) return null;

    final latestVersion = results[0]['version']?.toString();
    final storeUrl = results[0]['trackViewUrl']?.toString();
    if (latestVersion == null || storeUrl == null) return null;

    if (_isNewer(latestVersion, packageInfo.version)) {
      return AppUpdateInfo(
        currentVersion: packageInfo.version,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
      );
    }
    return null;
  }

  static Future<AppUpdateInfo?> _checkPlayStore(
      PackageInfo packageInfo) async {
    // Pas d'API officielle publique côté Play Store : on lit la version
    // affichée sur la page publique de la fiche app. Best-effort — si le
    // format de la page change, on échoue silencieusement (catch global
    // dans checkForUpdate()).
    final storeUrl =
        'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
    final response = await _dio.get(
      storeUrl,
      queryParameters: {'hl': 'fr'},
      options: Options(responseType: ResponseType.plain),
    );

    final html = response.data.toString();
    final match =
        RegExp(r'Current Version.*?>([\d.]+)<').firstMatch(html) ??
            RegExp(r'"[\s]*([\d]+\.[\d]+(?:\.[\d]+)*)[\s]*"[\s]*,[\s]*"[\s]*Current Version')
                .firstMatch(html);
    final latestVersion = match?.group(1);
    if (latestVersion == null) return null;

    if (_isNewer(latestVersion, packageInfo.version)) {
      return AppUpdateInfo(
        currentVersion: packageInfo.version,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
      );
    }
    return null;
  }

  /// Compare deux versions "x.y.z" (numérique, segment par segment).
  static bool _isNewer(String remote, String local) {
    final r = remote.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final l = local.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final length = r.length > l.length ? r.length : l.length;

    for (var i = 0; i < length; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv != lv) return rv > lv;
    }
    return false;
  }
}

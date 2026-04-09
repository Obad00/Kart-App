import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Service pour collecter automatiquement les informations de l'appareil
class DeviceInfoService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Collecte automatiquement les informations de l'appareil
  static Future<Map<String, String?>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return await _getWebInfo();
      } else if (Platform.isAndroid) {
        return await _getAndroidInfo();
      } else if (Platform.isIOS) {
        return await _getIOSInfo();
      }
    } catch (e) {
      debugPrint('Erreur collecte device info: $e');
    }

    return {
      'device': 'Unknown',
      'platform': 'Unknown',
    };
  }

  static Future<Map<String, String?>> _getAndroidInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;

    return {
      'device': '${androidInfo.manufacturer} ${androidInfo.model}',
      'platform': 'Android ${androidInfo.version.release}',
      'deviceId': androidInfo.id,
    };
  }

  static Future<Map<String, String?>> _getIOSInfo() async {
    final iosInfo = await _deviceInfo.iosInfo;

    return {
      'device': '${iosInfo.name} ${iosInfo.model}',
      'platform': 'iOS ${iosInfo.systemVersion}',
      'deviceId': iosInfo.identifierForVendor,
    };
  }

  static Future<Map<String, String?>> _getWebInfo() async {
    final webInfo = await _deviceInfo.webBrowserInfo;

    return {
      'device': '${webInfo.browserName} on ${webInfo.platform}',
      'platform': 'Web',
      'userAgent': webInfo.userAgent,
    };
  }

  /// Génère une chaîne descriptive de l'appareil pour affichage
  static Future<String> getDeviceDescription() async {
    final info = await getDeviceInfo();
    return info['device'] ?? 'Appareil inconnu';
  }

  /// Génère un user agent personnalisé
  static Future<String> getUserAgent() async {
    final info = await getDeviceInfo();

    if (info['userAgent'] != null) {
      return info['userAgent']!;
    }

    return 'KartApp/${info['platform']} (${info['device']})';
  }
}

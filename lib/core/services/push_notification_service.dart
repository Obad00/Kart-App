import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../shared/utils/jobmatch_access.dart';
import '../network/api_client.dart';

/// Notifications push (FCM) : demande des sons de connexion Explorer
/// (reçue/acceptée) et JobMatch (nouvelle candidature côté recruteur,
/// nouvelles offres côté candidat).
///
/// Toujours envoyées par le backend avec un bloc `notification` ET un bloc
/// `data` (voir PushNotificationService.php côté Laravel) : en arrière-plan
/// ou app fermée, le système affiche la notification tout seul (pas de
/// handler background nécessaire côté Dart) — on ne gère que le premier
/// plan (affichage manuel) et l'ouverture au tap (navigation).
class PushNotificationService {
  PushNotificationService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static const _androidChannel = AndroidNotificationChannel(
    'kart_default_channel',
    'Notifications',
    description: 'Demandes de mise en relation et offres JobMatch',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('⚠️ Firebase.initializeApp a échoué: $e');
      return;
    }

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('⚠️ Demande de permission notifications échouée: $e');
    }

    // iOS : laisse le système afficher la bannière nativement au premier
    // plan (évite un doublon avec flutter_local_notifications, utilisé lui
    // uniquement pour Android — FCM ne remonte pas au tiroir de
    // notifications côté Android quand l'app est au premier plan).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleData(message.data),
    );
    _onTokenRefreshSub = messaging.onTokenRefresh.listen((_) => registerToken());

    // Notification qui a servi à ouvrir l'app (cold start).
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleData(initialMessage.data);
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    _onTokenRefreshSub?.cancel();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Permissions déjà demandées explicitement via
    // FirebaseMessaging.requestPermission() — pas besoin de les redemander.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          _handleData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        } catch (_) {}
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Enregistre (ou met à jour) le token FCM de cet appareil côté backend —
  /// appelé après chaque connexion réussie (voir AuthProvider.loadMe()).
  /// Volontairement silencieux en cas d'échec : ne doit jamais bloquer
  /// l'authentification. Statique (pas besoin de _navigatorKey) pour rester
  /// appelable depuis AuthProvider sans référence au singleton du widget
  /// racine.
  static Future<void> registerToken() async {
    if (kIsWeb) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await ApiClient.dio.post('/device-tokens', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('⚠️ Enregistrement du token push échoué: $e');
    }
  }

  /// Supprime le token FCM de cet appareil côté backend — appelé avant la
  /// déconnexion (tant que le header Authorization est encore présent), pour
  /// que l'appareil arrête de recevoir des notifications une fois
  /// déconnecté.
  static Future<void> deleteToken() async {
    if (kIsWeb) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await ApiClient.dio.delete('/device-tokens', data: {'token': token});
    } catch (e) {
      debugPrint('⚠️ Suppression du token push échouée: $e');
    }
  }

  void _handleData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      final context = _navigatorKey.currentContext;
      if (navigator == null || context == null) return;

      switch (type) {
        case 'connection_request_received':
        case 'connection_request_accepted':
          final showJobMatch = canAccessJobMatch(
            context.read<AuthProvider>().user?.plan,
          );
          navigator.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
            arguments: {'tab': showJobMatch ? 3 : 2}, // Explorer
          );
          break;

        case 'jobmatch_new_match':
          // Nouvelle candidature (côté recruteur) — tableau de bord Matchs.
          navigator.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
            arguments: {'tab': 2, 'openDashboardTab': 0},
          );
          break;

        case 'jobmatch_new_suggestions':
          // Digest quotidien (côté candidat) — fil d'offres.
          navigator.pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
            arguments: {'tab': 2},
          );
          break;
      }
    });
  }
}

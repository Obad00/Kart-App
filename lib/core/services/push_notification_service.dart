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
import '../../firebase_options_web.dart';
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
///
/// Web : même flux (token FCM enregistré via [registerToken]), mais avec sa
/// propre config (voir firebase_options_web.dart) et son propre "système" —
/// le service worker web/firebase-messaging-sw.js, qui affiche la
/// notification en arrière-plan/onglet fermé. Au premier plan, en revanche,
/// rien n'est affiché sur le web (flutter_local_notifications ne supporte
/// pas cette plateforme) — limitation connue, pas un oubli.
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
      // Android/iOS lisent leur config nativement (google-services.json /
      // GoogleService-Info.plist) — seul le web a besoin qu'on la lui passe
      // explicitement, il n'a pas d'équivalent.
      await Firebase.initializeApp(
        options: kIsWeb ? webFirebaseOptions : null,
      );
    } catch (e) {
      debugPrint('⚠️ Firebase.initializeApp a échoué: $e');
      return;
    }

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '🔔 Permission notifications: ${settings.authorizationStatus}',
      );
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
    _onTokenRefreshSub =
        messaging.onTokenRefresh.listen((_) => registerToken());

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
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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
    final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
    var apnsTokenPresent = kIsWeb || !Platform.isIOS; // sans objet hors iOS

    try {
      final messaging = FirebaseMessaging.instance;

      // Le web a besoin de la clé VAPID pour obtenir un token — absente/
      // ignorée sur mobile, où c'est géré nativement (FCM/APNs).
      String? token;
      for (var attempt = 1; attempt <= 15; attempt++) {
        try {
          token =
              await messaging.getToken(vapidKey: kIsWeb ? webVapidKey : null);
          break;
        } on FirebaseException catch (e) {
          // Constaté en prod sur iOS : même une fois le token APNs natif
          // disponible, getToken() peut encore lever cette erreur juste
          // après — condition de course connue côté SDK natif, pas
          // seulement "pas encore prêt du tout". On retente donc l'appel
          // lui-même (jusqu'à ~30s cumulés) plutôt que de se contenter
          // d'attendre une fois avant, qui ne suffisait pas.
          if (e.code != 'apns-token-not-set' || attempt == 15) rethrow;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (!kIsWeb && Platform.isIOS) {
        apnsTokenPresent = await messaging.getAPNSToken() != null;
      }

      if (token == null) {
        // Cas silencieux le plus fréquent sur iOS : permission refusée par
        // l'utilisateur (ou pas encore accordée), ou token APNs toujours pas
        // disponible après l'attente ci-dessus — FirebaseMessaging.getToken()
        // ne lève pas d'exception dans ce cas, il renvoie juste null. On
        // remonte le statut d'autorisation au backend (voir _reportDiagnostic)
        // pour pouvoir le voir sans Mac/Console.app.
        final settings = await messaging.getNotificationSettings();
        final reason =
            'Aucun token obtenu (permission: ${settings.authorizationStatus})';
        debugPrint('⚠️ $reason');
        await _reportDiagnostic(
          platform: platform,
          authorizationStatus: settings.authorizationStatus.name,
          apnsTokenPresent: apnsTokenPresent,
          error: reason,
        );
        return;
      }

      await ApiClient.dio.post('/device-tokens', data: {
        'token': token,
        'platform': platform,
      });
    } catch (e) {
      debugPrint('⚠️ Enregistrement du token push échoué: $e');
      await _reportDiagnostic(
        platform: platform,
        authorizationStatus: null,
        apnsTokenPresent: apnsTokenPresent,
        error: e.toString(),
      );
    }
  }

  /// Remonte au backend les cas où aucun token n'a pu être obtenu — sans ça,
  /// ces échecs (permission refusée, course APNs...) sont invisibles côté
  /// serveur, puisqu'aucune requête n'est jamais posée sur /device-tokens.
  /// Volontairement tolérant : un échec réseau ici ne doit jamais faire
  /// planter registerToken() lui-même (déjà dans son propre try/catch, mais
  /// on s'en protège explicitement pour rester appelable depuis deux points
  /// différents de la fonction).
  static Future<void> _reportDiagnostic({
    required String platform,
    required String? authorizationStatus,
    required bool apnsTokenPresent,
    required String error,
  }) async {
    try {
      await ApiClient.dio.post('/device-tokens/diagnostic', data: {
        'platform': platform,
        'authorization_status': authorizationStatus,
        'apns_token_present': apnsTokenPresent,
        'error': error,
      });
    } catch (_) {}
  }

  /// Supprime le token FCM de cet appareil côté backend — appelé avant la
  /// déconnexion (tant que le header Authorization est encore présent), pour
  /// que l'appareil arrête de recevoir des notifications une fois
  /// déconnecté.
  static Future<void> deleteToken() async {
    try {
      final token = await FirebaseMessaging.instance
          .getToken(vapidKey: kIsWeb ? webVapidKey : null);
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
            arguments: {
              'tab': showJobMatch ? 3 : 2, // Explorer
              'openExploreTab': 1, // Mes demandes
            },
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

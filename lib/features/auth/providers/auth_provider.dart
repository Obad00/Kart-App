import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/notification_prefs.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';

const String _kGoogleSignInClientId =
    String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID', defaultValue: '');

// Client OAuth "Web" du projet Google Cloud : sur Android, l'ID token
// n'est émis que si on le fournit, et il sert alors d'audience ("aud")
// vérifiée par le backend (GOOGLE_ALLOWED_CLIENT_IDS).
const String _kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '51355966688-c2943v8dcbjikh2t9j8eqape67blo9a9.apps.googleusercontent.com',
);

enum DeleteAccountStatus {
  success,
  invalidPassword,
  sessionExpired,
  error,
}

class DeleteAccountResult {
  final DeleteAccountStatus status;
  final String? message;

  const DeleteAccountResult({required this.status, this.message});
}

class AuthProvider extends ChangeNotifier {
  final AuthApi _api = AuthApi();
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: kIsWeb && _kGoogleSignInClientId.isNotEmpty
        ? _kGoogleSignInClientId
        : null,
    // Non supporté sur le web (assertion du plugin).
    serverClientId: kIsWeb ? null : _kGoogleServerClientId,
  );

  bool get _isGoogleSignInConfigured =>
      !kIsWeb || _kGoogleSignInClientId.isNotEmpty;

  bool get isPro => user?.isPro ?? false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isAppleLoading = false;

  /// "Se connecter avec Apple" n'est proposé que sur iOS/macOS (flux natif) —
  /// Apple ne l'impose que là où une connexion tierce (Google) est proposée.
  bool get isAppleSignInAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
  bool isNewUser = false;
  User? user;
  String? error;
  String? errorDetails;

  /// Indique si l'initialisation (vérification du token) est terminée
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Appelé quand la session expire en cours d'usage (token devenu
  /// invalide côté serveur, détecté par loadMe()) — branché depuis
  /// main.dart sur resetSessionProviders(), pour que les autres providers
  /// (profil, compétences, contacts...) soient vidés même dans ce cas,
  /// pas seulement lors d'une déconnexion manuelle explicite. AuthProvider
  /// n'a pas de BuildContext pour appeler ça lui-même directement.
  VoidCallback? onSessionExpired;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await ApiClient.init();
      final token = await ApiClient.getToken();
      debugPrint('🔑 Token found on startup: ${token != null ? "Yes" : "No"}');
      if (token != null) {
        await _loadMeWithRetry();
      }
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Signalé : "je clique sur une notification (demande de connexion) et je
  /// suis déconnecté". Cause réelle — au lancement à froid déclenché par un
  /// tap sur une notification, Firebase/FCM (init, permission, jeton) se
  /// dispute la connexion réseau au même moment que ce tout premier /me :
  /// un raté transitoire (timeout, DNS pas encore prêt...) laissait `user`
  /// à null pour TOUTE la session, malgré un jeton valide en stockage — ni
  /// SplashScreen ni le handler de notification (qui attendent tous deux
  /// waitForInit() puis vérifient isAuthenticated) ne pouvaient alors
  /// deviner qu'il s'agissait d'un raté réseau plutôt que d'une vraie
  /// déconnexion, et renvoyaient vers /login. 2 tentatives de plus avant
  /// d'abandonner — uniquement pour un échec réseau/inconnu (loadMe() met
  /// `error` à une valeur non nulle dans ce cas précis) : un vrai 401/403
  /// appelle logout() qui remet `error` à null, ce qui arrête aussitôt les
  /// tentatives (pas la peine de réessayer une déconnexion légitime).
  Future<void> _loadMeWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await loadMe();
      if (user != null || error == null) return;
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }

  /// Attend que l'initialisation soit terminée
  Future<void> waitForInit() async {
    if (_isInitialized) return;
    // Attendre jusqu'à ce que l'initialisation soit terminée
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> loadMe() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final meResponse = await _api.me();
      debugPrint('👤 /me response: \\${meResponse.data}');
      user = User.fromJson(meResponse.data);
      // Fire-and-forget : ne doit jamais bloquer/faire échouer le chargement
      // de l'utilisateur (couvre login, loginWithGoogle et l'auto-connexion
      // au démarrage, qui passent tous par loadMe()). On respecte la
      // préférence "Notifications" des Réglages : sans cette vérification,
      // une désactivation manuelle serait silencieusement annulée à chaque
      // reconnexion.
      unawaited(NotificationPrefs.isEnabled().then((enabled) {
        if (enabled) PushNotificationService.registerToken();
      }));
    } on DioException catch (e) {
      debugPrint(
          '❌ /me DioException: status=\\${e.response?.statusCode}, data=\\${e.response?.data}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
        onSessionExpired?.call();
      } else {
        error = 'Impossible de récupérer l\'utilisateur';
      }
    } catch (e) {
      debugPrint('❌ /me unknown error: \\${e.toString()}');
      error = 'Une erreur est survenue';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // debugPrint('🔐 Attempting login for: $email');
      final response = await _api.login(email, password);
      debugPrint('🔐 Login response: ${response.data}');

      // Handle both 'access_token' and 'token' field names from backend
      final token = response.data['access_token'] ?? response.data['token'];
      if (token == null || token is! String) {
        debugPrint('❌ No token in response: ${response.data}');
        error = 'Erreur: token non reçu';
        return;
      }

      await ApiClient.setToken(token);
      // debugPrint('✅ Token saved');

      // ✅ TOUJOURS charger depuis /me pour avoir la relation company
      // debugPrint('🔄 Loading user from /me to get company relation...');
      await loadMe();
      // debugPrint('✅ User fully loaded: ${user?.email}');
      // debugPrint('✅ Company: ${user?.company?.name}');
    } on DioException catch (e) {
      // debugPrint('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
      // Le backend dit maintenant précisément ce qui cloche (identifiant
      // inconnu / mot de passe / compte désactivé, cf. AuthService::login)
      // — on affiche SON message plutôt que le "Email ou mot de passe
      // incorrect" fourre-tout d'avant, qui masquait l'information.
      error = getErrorMessage(
        e,
        fallback: e.response?.statusCode == 401
            ? 'Email ou mot de passe incorrect'
            : 'Erreur serveur, réessayez',
      );
    } catch (e) {
      // debugPrint('❌ Unknown error: $e');
      error = 'Une erreur est survenue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.register({
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': 'user',
      });

      // Registration successful, now login automatically
      await login(email, password);
    } on DioException catch (e) {
      debugPrint(
          '❌ Register DioException: ${e.response?.statusCode} - ${e.response?.data}');
      error = getErrorMessage(e, fallback: 'Erreur serveur, réessayez');
    } catch (e) {
      debugPrint('❌ Register unknown error: $e');
      error = 'Erreur inattendue: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour la photo de profil (remplace l'initiale affichée par
  /// défaut) puis recharge l'utilisateur pour refléter le changement.
  Future<void> updateAvatar(Uint8List bytes, String filename) async {
    try {
      await _api.updateAvatar(bytes, filename);
      await loadMe();
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e,
          fallback: 'Erreur lors de la mise à jour de la photo'));
    }
  }

  Future<void> deleteAvatar() async {
    try {
      await _api.deleteAvatar();
      await loadMe();
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e,
          fallback: 'Erreur lors de la suppression de la photo'));
    }
  }

  Future<void> logout() async {
    if (kIsWeb && !_isGoogleSignInConfigured) {
      debugPrint(
          'GoogleSignIn logout skipped: missing web client ID configuration');
    } else {
      try {
        await _googleSignIn.signOut();
      } catch (e, st) {
        debugPrint('GoogleSignIn signOut error: $e\n$st');
      }
    }

    // Avant de vider le token d'auth : l'appel DELETE /device-tokens a
    // besoin du header Authorization pour identifier l'utilisateur.
    await PushNotificationService.deleteToken();

    await ApiClient.clearToken();
    await ApiClient.clearOfflineCache();
    await _clearUserLocalCaches();
    user = null;
    error = null;
    isNewUser = false;
    notifyListeners();
  }

  Future<void> _clearUserLocalCaches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_plan_slug');
  }

  /// [password] null pour un compte Google/Apple sans mot de passe.
  Future<DeleteAccountResult> deleteAccount(String? password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _api.deleteAccount(password);
      final statusCode = response.statusCode ?? 0;
      final data = response.data;

      if (statusCode == 200) {
        await logout();
        return const DeleteAccountResult(
          status: DeleteAccountStatus.success,
          message: 'Votre compte a été supprimé avec succès',
        );
      }

      if (statusCode == 422) {
        String message = 'Mot de passe incorrect';
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map &&
              errors['password'] is List &&
              (errors['password'] as List).isNotEmpty) {
            message = (errors['password'] as List).first.toString();
          } else if (data['message'] != null) {
            message = data['message'].toString();
          }
        }
        return DeleteAccountResult(
          status: DeleteAccountStatus.invalidPassword,
          message: message,
        );
      }

      if (statusCode == 401) {
        await logout();
        return const DeleteAccountResult(
          status: DeleteAccountStatus.sessionExpired,
          message: 'Session expirée',
        );
      }

      return const DeleteAccountResult(
        status: DeleteAccountStatus.error,
        message: 'Une erreur est survenue. Veuillez réessayer.',
      );
    } on DioException catch (e) {
      debugPrint("DELETE ACCOUNT ERROR");
      debugPrint("Status : ${e.response?.statusCode}");
      debugPrint("Data : ${e.response?.data}");
      debugPrint("Message : ${e.message}");

      return DeleteAccountResult(
        status: DeleteAccountStatus.error,
        message: e.response?.data.toString() ?? e.message,
      );
    } catch (_) {
      return const DeleteAccountResult(
        status: DeleteAccountStatus.error,
        message: 'Une erreur est survenue. Veuillez réessayer.',
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String firstname,
    required String lastname,
    String? phone,
    String? email,
    String? password,
    String? passwordConfirmation,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'firstname': firstname,
        'lastname': lastname,
      };

      if (phone != null && phone.isNotEmpty) {
        data['phone'] = phone;
      }

      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }

      if (password != null && password.isNotEmpty) {
        data['password'] = password;
        if (passwordConfirmation != null) {
          data['password_confirmation'] = passwordConfirmation;
        }
      }

      await _api.updateProfile(data);

      // Recharger les donnees de l'utilisateur
      await loadMe();

      return true;
    } on DioException catch (e) {
      debugPrint(
          'Update profile error: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            error = firstError.first.toString();
          } else {
            error = data['message'] ?? 'Donnees invalides';
          }
        } else if (data is Map && data['message'] != null) {
          error = data['message'];
        } else {
          error = 'Donnees invalides';
        }
      } else {
        error = 'Erreur lors de la mise a jour du profil';
      }
      return false;
    } catch (e) {
      debugPrint('Update profile unknown error: $e');
      error = 'Une erreur est survenue';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: newPasswordConfirmation,
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200) {
        final data = response.data;
        if (data is Map && data['user'] != null) {
          user = User.fromJson(Map<String, dynamic>.from(data['user']));
        } else {
          await loadMe();
        }
        return true;
      }

      final data = response.data;
      if (data is Map && data['errors'] != null) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        error = firstError is List && firstError.isNotEmpty
            ? firstError.first.toString()
            : (data['message']?.toString() ?? 'Données invalides');
      } else if (data is Map && data['message'] != null) {
        error = data['message'].toString();
      } else {
        error = 'Une erreur est survenue';
      }
      return false;
    } catch (e) {
      debugPrint('Change password unknown error: $e');
      error = 'Une erreur est survenue';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _api.forgotPassword(email);
      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200) {
        return true;
      }

      final data = response.data;
      if (data is Map && data['errors'] != null) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        error = firstError is List && firstError.isNotEmpty
            ? firstError.first.toString()
            : (data['message']?.toString() ?? 'Données invalides');
      } else if (data is Map && data['message'] != null) {
        error = data['message'].toString();
      } else {
        error = 'Une erreur est survenue';
      }
      return false;
    } catch (e) {
      debugPrint('Forgot password unknown error: $e');
      error = 'Une erreur est survenue';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    isGoogleLoading = true;
    error = null;
    errorDetails = null;
    notifyListeners();

    try {
      if (kIsWeb && !_isGoogleSignInConfigured) {
        error =
            'Google sign-in non configuré pour le web. Ajoutez un client_id dans web/index.html ou utilisez --dart-define=GOOGLE_SIGN_IN_CLIENT_ID=...';
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // annulé par l'utilisateur

      final idToken = (await googleUser.authentication).idToken;
      if (idToken == null) {
        error = 'Impossible d\'obtenir le jeton Google';
        return;
      }

      await _completeSocialLogin(await _api.googleLogin(idToken));
    } on DioException catch (e) {
      error = getErrorMessage(e, fallback: 'Erreur de connexion Google');
      debugPrint('❌ Google login: $e');
    } catch (e, st) {
      error = 'Erreur de connexion avec Google';
      debugPrint('❌ Google login: $e\n$st');
    } finally {
      isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithApple() async {
    isAppleLoading = true;
    error = null;
    errorDetails = null;
    notifyListeners();

    try {
      // Nonce anti-rejeu : Apple embarque son SHA-256 dans le jeton, le
      // backend le compare au nonce en clair qu'on lui envoie.
      final rawNonce = _generateNonce();
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        error = 'Impossible d\'obtenir le jeton Apple';
        return;
      }

      // Apple ne fournit le nom qu'à la toute première autorisation.
      await _completeSocialLogin(await _api.appleLogin(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        nonce: rawNonce,
        firstname: credential.givenName,
        lastname: credential.familyName,
      ));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        error = 'Erreur de connexion avec Apple';
        debugPrint('❌ Apple login: ${e.code} ${e.message}');
      }
    } on DioException catch (e) {
      error = getErrorMessage(e, fallback: 'Erreur de connexion Apple');
      debugPrint('❌ Apple login: $e');
    } catch (e, st) {
      error = 'Erreur de connexion avec Apple';
      debugPrint('❌ Apple login: $e\n$st');
    } finally {
      isAppleLoading = false;
      notifyListeners();
    }
  }

  /// Réponse commune de /auth/google/token et /auth/apple/token.
  Future<void> _completeSocialLogin(Response response) async {
    final token = response.data['access_token'] ?? response.data['token'];
    if (token == null || token is! String) {
      error = 'Erreur: token non reçu';
      return;
    }

    await ApiClient.setToken(token);
    isNewUser = response.data['is_new_user'] == true;
    await loadMe();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  bool get isAuthenticated => user != null;
}

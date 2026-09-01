import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  );

  bool get _isGoogleSignInConfigured =>
      !kIsWeb || _kGoogleSignInClientId.isNotEmpty;

  bool get isPro => user?.isPro ?? false;
  bool isLoading = false;
  bool isGoogleLoading = false;
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
        await loadMe();
      }
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
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
      if (e.response?.statusCode == 401) {
        error = 'Email ou mot de passe incorrect';
      } else {
        error = getErrorMessage(e, fallback: 'Erreur serveur, réessayez');
      }
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

  Future<DeleteAccountResult> deleteAccount(String password) async {
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
    notifyListeners();

    try {
      if (kIsWeb && !_isGoogleSignInConfigured) {
        error =
            'Google sign-in non configuré pour le web. Ajoutez un client_id dans web/index.html ou utilisez --dart-define=GOOGLE_SIGN_IN_CLIENT_ID=...';
        isGoogleLoading = false;
        notifyListeners();
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isGoogleLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        error = 'Impossible d\'obtenir le token Google';
        isGoogleLoading = false;
        notifyListeners();
        return;
      }

      final response = await _api.googleLogin(accessToken);
      // Handle both 'access_token' and 'token' field names from backend
      final token = response.data['access_token'] ?? response.data['token'];

      if (token == null || token is! String) {
        error = 'Erreur: token non reçu';
        isGoogleLoading = false;
        notifyListeners();
        return;
      }

      await ApiClient.setToken(token);
      isNewUser = response.data['is_new_user'] == true;

      await loadMe();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        error = 'Token Google invalide';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        error = e.response?.data['message'];
      } else {
        error = 'Erreur de connexion Google';
      }
      errorDetails = e.toString();
    } catch (e, st) {
      error = 'Erreur de connexion avec Google';
      errorDetails = '$e\n$st';
    } finally {
      isGoogleLoading = false;
      notifyListeners();
    }
  }

  bool get isAuthenticated => user != null;
}

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';

const String _kGoogleSignInClientId =
    String.fromEnvironment('GOOGLE_SIGN_IN_CLIENT_ID', defaultValue: '');
const String _kAppleServiceId =
    String.fromEnvironment('APPLE_SERVICE_ID', defaultValue: '');
const String _kAppleRedirectUri =
    String.fromEnvironment('APPLE_REDIRECT_URI', defaultValue: '');

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
  bool isAppleLoading = false;
  bool isNewUser = false;
  User? user;
  String? error;
  String? errorDetails;

  /// Indique si l'initialisation (vérification du token) est terminée
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

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
    errorDetails = null;
    notifyListeners();

    try {
      final meResponse = await _api.me();
      debugPrint('👤 /me response: ${meResponse.data}');
      user = User.fromJson(meResponse.data);
    } on DioException catch (e) {
      debugPrint(
          '❌ /me DioException: status=${e.response?.statusCode}, data=${e.response?.data}');
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
      } else {
        error = 'Impossible de récupérer l\'utilisateur';
        errorDetails = _extractBackendMessage(e.response?.data);
      }
    } catch (e) {
      debugPrint('❌ /me unknown error: ${e.toString()}');
      error = 'Une erreur est survenue';
      errorDetails = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    errorDetails = null;
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
        errorDetails = response.data.toString();
        return;
      }

      await ApiClient.setToken(token);
      // debugPrint('✅ Token saved');

      // ✅ TOUJOURS charger depuis /me pour avoir la relation company
      // debugPrint('🔄 Loading user from /me to get company relation...');
      await loadMe();
      if (!isAuthenticated && error == null) {
        error = 'Impossible de terminer la connexion. Réessayez.';
      }
      // debugPrint('✅ User fully loaded: ${user?.email}');
      // debugPrint('✅ Company: ${user?.company?.name}');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final backendMessage = _extractBackendMessage(responseData);

      if (e.response?.statusCode == 401) {
        if (backendMessage?.contains('Compte inactif') == true) {
          error = 'Compte inactif';
        } else {
          error = 'Email ou mot de passe incorrect';
          errorDetails = backendMessage;
        }
      } else if (e.response?.statusCode == 403) {
        error = backendMessage ?? 'Accès refusé. Contactez le support.';
        errorDetails = backendMessage;
      } else if (e.response?.statusCode == 419) {
        error = 'La session a expiré. Veuillez réessayer.';
        errorDetails = backendMessage;
      } else if (e.response?.statusCode == 422) {
        if (backendMessage != null) {
          error = backendMessage;
        } else {
          error = 'Données invalides';
        }
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        error = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
      } else {
        error = backendMessage ?? 'Erreur serveur, réessayez';
        errorDetails = backendMessage;
      }
    } catch (e) {
      // debugPrint('❌ Unknown error: $e');
      error = 'Une erreur est survenue: $e';
      errorDetails = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
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
      final response = await _api.register({
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': 'user',
      });

      final responseData = response.data;
      if (responseData is Map &&
          responseData['requires_email_verification'] == true) {
        error = 'verification_required';
        return true;
      }

      // Registration successful, now login automatically
      await login(email, password);
      return true;
    } on DioException catch (e) {
      debugPrint(
          '❌ Register DioException: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 422) {
        // Erreur de validation
        final data = e.response?.data;
        if (data is Map && data['errors'] != null) {
          // Laravel renvoie les erreurs de validation dans 'errors'
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            error = firstError.first.toString();
          } else {
            error = data['message'] ?? 'Données invalides';
          }
        } else if (data is Map && data['message'] != null) {
          error = data['message'];
        } else {
          error = 'Données invalides';
        }
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        error = 'Impossible de contacter le serveur. Vérifiez votre connexion.';
      } else {
        error = 'Erreur serveur: ${e.response?.statusCode ?? "inconnue"}';
      }
      return false;
    } catch (e) {
      debugPrint('❌ Register unknown error: $e');
      error = 'Erreur inattendue: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activateAccount(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _api.activateAccount(token);
      final authToken = response.data['access_token'] ?? response.data['token'];
      if (authToken == null || authToken is! String) {
        error = 'Erreur: token non reçu';
        return false;
      }

      await ApiClient.setToken(authToken);
      await loadMe();
      return true;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        error = responseData['message'];
      } else {
        error = 'Code d\'activation invalide ou expiré';
      }
      return false;
    } catch (e) {
      error = 'Une erreur est survenue lors de l\'activation';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    isLoading = true;
    error = null;
    errorDetails = null;
    notifyListeners();

    try {
      await _api.resendVerificationEmail(email);
      return true;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map && responseData['message'] != null) {
        error = responseData['message'];
      } else {
        error = 'Impossible de renvoyer l\'email de vérification';
      }
      return false;
    } catch (e) {
      error = 'Une erreur est survenue';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
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

    await ApiClient.clearToken();
    user = null;
    error = null;
    isNewUser = false;
    notifyListeners();
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

  Future<void> loginWithApple() async {
    isAppleLoading = true;
    error = null;
    errorDetails = null;
    notifyListeners();

    try {
      final usesWebAppleFlow =
          kIsWeb || defaultTargetPlatform == TargetPlatform.android;

      if (usesWebAppleFlow &&
          (_kAppleServiceId.isEmpty || _kAppleRedirectUri.isEmpty)) {
        error =
            'Apple sign-in non configuré pour cette plateforme. Ajoutez APPLE_SERVICE_ID et APPLE_REDIRECT_URI.';
        isAppleLoading = false;
        notifyListeners();
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: usesWebAppleFlow
            ? WebAuthenticationOptions(
                clientId: _kAppleServiceId,
                redirectUri: Uri.parse(_kAppleRedirectUri),
              )
            : null,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        error = 'Impossible d\'obtenir le token Apple';
        isAppleLoading = false;
        notifyListeners();
        return;
      }

      final response = await _api.appleLogin(
        identityToken,
        firstname: credential.givenName,
        lastname: credential.familyName,
      );
      final token = response.data['access_token'] ?? response.data['token'];

      if (token == null || token is! String) {
        error = 'Erreur: token non reçu';
        isAppleLoading = false;
        notifyListeners();
        return;
      }

      await ApiClient.setToken(token);
      isNewUser = response.data['is_new_user'] == true;

      await loadMe();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        error = 'Erreur de connexion avec Apple';
        errorDetails = e.message;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        error = 'Token Apple invalide';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        error = e.response?.data['message'];
      } else if (e.response?.data != null &&
          e.response?.data['error'] != null) {
        error = e.response?.data['error'];
      } else {
        error = 'Erreur de connexion Apple';
      }
      errorDetails = e.toString();
    } catch (e, st) {
      error = 'Erreur de connexion avec Apple';
      errorDetails = '$e\n$st';
    } finally {
      isAppleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _api.deleteAccount();
      await logout();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        error = 'Connexion expirée';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        error = e.response?.data['message'];
      } else {
        error = 'Impossible de supprimer le compte';
      }
      return false;
    } catch (e) {
      error = 'Une erreur est survenue';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? _extractBackendMessage(dynamic data) {
    if (data is Map) {
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['error'] != null) {
        return data['error'].toString();
      }
      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }
          if (first is String) {
            return first;
          }
        }
      }
    }
    return null;
  }

  bool get isAuthenticated => user != null;
}

import 'package:flutter/material.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApi _api = AuthApi();


  bool get isPro => user?.isPro ?? false;
  bool isLoading = false;
  User? user;  String? error; // ✅ AJOUTÉ

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Ensure ApiClient has the token from storage (if any) and try to load the current user
    await ApiClient.init();
    final token = await ApiClient.getToken();
    if (token != null) {
      await loadMe();
    }
  }

  /// Loads the authenticated user's profile from /api/me
  Future<void> loadMe() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final meResponse = await _api.me();
      user = User.fromJson(meResponse.data);
    } on DioException catch (e) {
      // In case the token is invalid/expired, perform a silent logout
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
      } else {
        error = 'Impossible de récupérer l\'utilisateur';
      }
    } catch (_) {
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
      final response = await _api.login(email, password);
      final token = response.data['token'];

      await ApiClient.setToken(token);

      // Load the user's profile after setting token
      await loadMe();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        error = 'Email ou mot de passe incorrect';
      } else {
        error = 'Erreur serveur, réessayez';
      }
    } catch (_) {
      error = 'Une erreur est survenue';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstname,
    required String lastname,
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
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      final token = response.data['token'];
      await ApiClient.setToken(token);

      // Load profile after registration
      await loadMe();
    } on DioException catch (_) {
      error = 'Erreur lors de l\'inscription';
    } catch (_) {
      error = 'Erreur lors de l\'inscription';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    user = null;
    error = null;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;
}

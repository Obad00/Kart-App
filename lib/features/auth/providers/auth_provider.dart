import 'package:flutter/material.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApi _api = AuthApi();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isLoading = false;
  Map<String, dynamic>? user;
  String? error;

  Future<void> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await _api.login(email, password);
      final token = response.data['token'];

      await ApiClient.setToken(token);

      final meResponse = await _api.me();
      user = meResponse.data;
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

  Future<void> loginWithGoogle() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow — not an error
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        error = "Impossible d'obtenir le token Google";
        return;
      }

      final response = await _api.loginWithGoogle(idToken);
      final token = response.data['token'];

      await ApiClient.setToken(token);

      final meResponse = await _api.me();
      user = meResponse.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        error = 'Authentification Google refusée';
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

      final meResponse = await _api.me();
      user = meResponse.data;
    } catch (e) {
      error = "Erreur lors de l'inscription";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await ApiClient.clearToken();
    user = null;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;
}

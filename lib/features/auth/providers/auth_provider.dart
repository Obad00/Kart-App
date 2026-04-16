import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/auth_api.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApi _api = AuthApi();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool isLoading = false;
  Map<String, dynamic>? user;
  String? error; // ✅ AJOUTÉ

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
        // User cancelled the sign-in flow
        isLoading = false;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        error = "Impossible d'obtenir le token Google";
        isLoading = false;
        notifyListeners();
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
      error = 'Connexion Google échouée';
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        if (errors != null && errors is Map) {
          error = (errors.values.first as List).first.toString();
        } else {
          error = e.response?.data['message'] ?? "Erreur lors de l'inscription";
        }
      } else if (e.response?.statusCode != null) {
        error = 'Erreur serveur, réessayez';
      } else {
        error = 'Pas de connexion réseau';
      }
    } catch (e) {
      error = "Erreur lors de l'inscription";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    await _googleSignIn.signOut();
    user = null;
    notifyListeners();
  }

  bool get isAuthenticated => user != null;
}

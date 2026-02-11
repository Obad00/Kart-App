import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le thème de l'application
/// Le mode Light est réservé aux utilisateurs Premium et Entreprise
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isInitialized = false;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Charge le thème sauvegardé depuis les préférences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = _themeModeFromString(savedTheme);
      }
    } catch (_) {
      // En cas d'erreur, garder le thème dark par défaut
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change le thème (vérifie les permissions)
  /// Retourne true si le changement est effectué, false si non autorisé
  Future<bool> setThemeMode(ThemeMode mode, {required bool isPremiumOrCompany}) async {
    // Le mode Light nécessite un plan Premium ou Entreprise
    if (mode == ThemeMode.light && !isPremiumOrCompany) {
      return false;
    }

    _themeMode = mode;
    notifyListeners();

    // Sauvegarder le choix
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(mode));
    } catch (_) {}

    return true;
  }

  /// Bascule entre dark et light (pour les utilisateurs autorisés)
  Future<bool> toggleTheme({required bool isPremiumOrCompany}) async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    return setThemeMode(newMode, isPremiumOrCompany: isPremiumOrCompany);
  }

  /// Force le thème dark (pour les utilisateurs freemium)
  Future<void> forceDarkMode() async {
    if (_themeMode != ThemeMode.dark) {
      _themeMode = ThemeMode.dark;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeKey, 'dark');
      } catch (_) {}
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}

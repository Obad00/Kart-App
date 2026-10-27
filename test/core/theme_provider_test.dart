import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème clair par défaut pour qui n'a rien choisi ; un choix enregistré est
/// toujours respecté ; aucun plan requis.
Future<ThemeProvider> _loaded() async {
  final provider = ThemeProvider();
  while (!provider.isInitialized) {
    await Future<void>.delayed(Duration.zero);
  }
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('aucun choix enregistré : clair', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await _loaded()).themeMode, ThemeMode.light);
  });

  test('choix « sombre » déjà enregistré : gardé', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    expect((await _loaded()).themeMode, ThemeMode.dark);
  });

  test('choix « système » déjà enregistré : gardé', () async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
    expect((await _loaded()).themeMode, ThemeMode.system);
  });

  test('changer de thème est enregistré, sans condition de plan', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = await _loaded();

    await provider.setThemeMode(ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);
    expect((await SharedPreferences.getInstance()).getString('app_theme_mode'), 'dark');

    await provider.toggleTheme();
    expect(provider.themeMode, ThemeMode.light);
  });
}

import 'package:flutter/material.dart';

import 'kart_tokens.dart';

class AppTheme {
  AppTheme._();

  // Soft white used for text/icons to avoid pure white fatigue
  static const Color _softWhite = Color(0xFFF6F6F8);
  // Fond de page sombre, identique sur toutes les pages (cf. KartTokens) —
  // remplace l'ancien quasi-noir 0A0A0B/0D0D0E pour s'aligner sur le
  // #1A1A1A déjà utilisé par l'app (icône, feuilles).
  static final Color _softBlack = KartTokens.dark.pageBackground;
  static final Color _surface = KartTokens.dark.pageBackground;
  // Bordure discrète des cartes en mode sombre (même rôle que _outlineLight).
  // ~12% était quasi invisible sur fond quasi noir — remonté à ~24% pour
  // qu'elle se voie autant que la bordure grise du mode clair.
  static const Color _outlineDark = Color(0x3DFFFFFF); // Colors.white ~24%

  // Couleurs pour le mode light premium
  // Fond de page clair, identique sur toutes les pages (cf. KartTokens).
  // colorScheme.surface sert de fond de page partout (HomeShell, pages
  // embarquées) : il prend donc la même valeur que le scaffold.
  static final Color _lightBackground = KartTokens.light.pageBackground;
  static final Color _lightSurface = KartTokens.light.pageBackground;
  static const Color _lightCardBg = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1A1A2E);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _outlineLight = Color(0xFFE5E7EB);

  /// Rayon partagé par toutes les cartes du design system (CardTheme) et
  /// par la pilule de navigation flottante de HomeShell — une seule
  /// source de vérité pour que les deux suivent le même arrondi.
  static const double cardRadius = 20.0;

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
        extensions: const [KartTokens.light],
        scaffoldBackgroundColor: _lightBackground,
        primaryColor: _accentBlue,
        colorScheme: ColorScheme.light(
          primary: _accentBlue,
          secondary: _accentBlue,
          surface: _lightSurface,
          onPrimary: Colors.white,
          onSurface: _lightTextPrimary,
          onSecondary: Colors.white,
          outline: _outlineLight,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _lightSurface,
          foregroundColor: _lightTextPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black12,
        ),
        textTheme: base.textTheme.apply(fontFamily: 'Syne').copyWith(
              headlineLarge: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _lightTextPrimary,
                letterSpacing: -0.5,
              ),
              headlineMedium: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _lightTextPrimary,
              ),
              titleLarge: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _lightTextPrimary,
              ),
              bodyLarge: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 16,
                color: _lightTextPrimary,
              ),
              bodyMedium: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 14,
                color: _lightTextSecondary,
              ),
              labelMedium: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 12,
                color: _lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
        cardTheme: CardThemeData(
          color: _lightCardBg,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: const BorderSide(color: _outlineLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentBlue, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _lightTextSecondary),
          hintStyle:
              TextStyle(color: _lightTextSecondary.withValues(alpha: 0.6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _accentBlue,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: _accentBlue),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: _accentBlue,
          unselectedItemColor: _lightTextSecondary,
          elevation: 8,
        ),
        dividerColor: const Color(0xFFE5E7EB),
        splashColor: _accentBlue.withValues(alpha: 0.1),
        highlightColor: _accentBlue.withValues(alpha: 0.05));
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      extensions: const [KartTokens.dark],
      scaffoldBackgroundColor: _softBlack,
      primaryColor: _softWhite,
      colorScheme: ColorScheme.dark(
        primary: _softWhite,
        secondary: _softWhite,
        surface: _surface,
        onPrimary: _softBlack,
        onSurface: _softWhite,
        outline: _outlineDark,
      ),
      textTheme: base.textTheme.apply(
          bodyColor: _softWhite, displayColor: _softWhite, fontFamily: 'Syne'),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: _outlineDark),
        ),
      ),
      dividerColor: Colors.white12,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
    );
  }
}

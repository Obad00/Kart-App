import 'card_theme.dart';
import 'card_themes.dart';

DigitalCardTheme cardThemeFromBackend(String? value) {
  switch (value) {
    case 'dark_minimal':
      return CardThemes.darkMinimal;
    case 'clean_light':
      return CardThemes.cleanLight;
    default:
      return CardThemes.defaultTheme;
  }
}

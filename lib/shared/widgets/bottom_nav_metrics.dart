/// Métriques de la pilule de navigation flottante de [HomeShell] —
/// partagées avec les pages enfants pour qu'elles réservent la bonne place
/// en bas de leurs listes scrollables (HomeShell utilise `extendBody`, donc
/// le `MediaQuery.padding.bottom` qu'elles reçoivent ne compte déjà plus la
/// hauteur de la pilule, seulement la vraie safe area).
class BottomNavMetrics {
  BottomNavMetrics._();

  /// Hauteur du contenu de la pilule (cf. home_shell.dart : SizedBox(height: 56)).
  static const double pillHeight = 56;

  /// Marge verticale au-dessus ET en dessous de la pilule
  /// (EdgeInsets.symmetric(vertical: 6) dans home_shell.dart).
  static const double verticalMargin = 6;

  /// Place totale occupée par la pilule, hors safe area (à additionner à
  /// `MediaQuery.of(context).padding.bottom` pour obtenir le padding bas à
  /// donner à une liste/scrollable afin que son dernier élément reste
  /// entièrement atteignable au-dessus de la nav.
  static const double reservedHeight = pillHeight + verticalMargin * 2;

  /// Padding bas complet (safe area + pilule) à appliquer directement au
  /// bas d'un scrollable.
  static double bottomInset(double safeAreaBottom) =>
      safeAreaBottom + reservedHeight;
}

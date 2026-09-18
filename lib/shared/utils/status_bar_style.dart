import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Style de la barre de statut système (heure/batterie/réseau) à passer à
/// `AppBar(systemOverlayStyle: ...)` — remonté côté produit : sur un fond
/// transparent (`backgroundColor: Colors.transparent`, utilisé partout
/// dans l'app pour les AppBar "verre dépoli"), Flutter estime le style par
/// défaut à partir du RGB de cette couleur (0,0,0), sans tenir compte de
/// l'alpha — il en déduit systématiquement un fond "sombre" et impose des
/// icônes blanches, invisibles une fois le thème clair réellement affiché
/// derrière (ça ne fonctionnait par coïncidence qu'en thème sombre).
SystemUiOverlayStyle statusBarStyleFor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
}

import 'package:flutter/material.dart';

/// Icônes proposées pour un highlight — les clés sont celles acceptées par
/// le backend (Highlight::ICONS). Sans icône, l'initiale du nom est affichée.
class HighlightIcons {
  HighlightIcons._();

  static const Map<String, IconData> all = {
    'users': Icons.people_alt_rounded,
    'target': Icons.track_changes_rounded,
    'handshake': Icons.handshake_outlined,
    'star': Icons.star_rounded,
    'calendar': Icons.event_rounded,
    'briefcase': Icons.work_outline_rounded,
    'heart': Icons.favorite_rounded,
    'rocket': Icons.rocket_launch_rounded,
  };

  /// null pour une clé absente ou inconnue (ex: ajoutée côté backend plus
  /// tard) : l'appelant affiche alors l'initiale.
  static IconData? of(String? key) => key == null ? null : all[key];
}

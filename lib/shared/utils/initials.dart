/// Initiales (1 ou 2 lettres) à partir d'un nom complet — pour l'avatar de
/// repli affiché quand la personne n'a pas de photo.
///
/// Filtre les segments vides (`split(RegExp(r'\s+'))` + suppression des
/// entrées vides) avant d'indexer — contrairement aux ~8 implémentations
/// dupliquées que ce fichier remplace, qui plantaient (RangeError: Index
/// out of range) dès qu'un nom contenait un double espace ou un espace en
/// tête/fin (ex: "Amadou  Tall" → split(' ') donne ['Amadou', '', 'Tall'],
/// et parts[1][0] indexe une chaîne vide).
String getInitials(String name, {String fallback = ''}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return fallback;
  if (parts.length == 1) return parts.first[0].toUpperCase();
  final list = parts.toList();
  return (list[0][0] + list[1][0]).toUpperCase();
}

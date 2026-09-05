/// "Publié il y a X jours" — utilisé par les cartes/lignes JobMatch, pour
/// l'ancienneté d'une offre (published_at).
String relativeTimeLabel(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inDays >= 1) {
    final days = diff.inDays;
    return 'il y a $days jour${days > 1 ? 's' : ''}';
  }
  if (diff.inHours >= 1) {
    final hours = diff.inHours;
    return 'il y a $hours heure${hours > 1 ? 's' : ''}';
  }
  if (diff.inMinutes >= 1) {
    final minutes = diff.inMinutes;
    return 'il y a $minutes minute${minutes > 1 ? 's' : ''}';
  }
  return "à l'instant";
}

/// Affichage d'un numéro, comme sur le site (formatPhone) :
/// « +221 77 000 01 01 » pour un numéro sénégalais, tel quel sinon.
///
/// Affichage UNIQUEMENT : le numéro envoyé au backend reste celui reçu ou
/// saisi, c'est le backend qui le normalise (PhoneNumber::normalize).
String formatPhoneForDisplay(String phone) {
  // Séparateurs courants ignorés, pour qu'un numéro du carnet d'adresses
  // (« 77 000-01.01 », « 00221… ») s'affiche comme celui de la liste.
  final compact = phone.trim().replaceAll(RegExp(r'[\s.\-()]'), '');
  final match = RegExp(r'^(?:\+221|00221)?([37]\d)(\d{3})(\d{2})(\d{2})$').firstMatch(compact);
  if (match == null) return phone.trim();
  return '+221 ${match[1]} ${match[2]} ${match[3]} ${match[4]}';
}

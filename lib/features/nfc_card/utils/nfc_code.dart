/// Code d'une carte NFC KART : 8 caractères, majuscules et chiffres.
const int nfcCodeLength = 8;

/// Extrait le code d'une carte à partir de ce que l'utilisateur a saisi OU
/// de ce qui est lu sur la puce : le code seul (« abcd 2345 »), ou le lien
/// gravé (« https://kart.business/t/ABCD2345 »). Renvoie le code en
/// majuscules, sans espaces ; null si rien d'exploitable.
String? extractNfcCode(String? input) {
  if (input == null) return null;
  var value = input.trim();
  if (value.isEmpty) return null;

  // Lien gravé sur la puce : le code est le segment qui suit /t/.
  final match = RegExp(r'/t/([A-Za-z0-9]+)').firstMatch(value);
  if (match != null) {
    value = match.group(1)!;
  } else if (value.contains('/') || value.contains('.')) {
    // Un autre lien (pas une carte KART) : pas de code.
    return null;
  }

  final code = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return RegExp(r'^[A-Z0-9]+$').hasMatch(code) ? code : null;
}

/// Le code a-t-il la bonne longueur pour être envoyé au serveur ?
bool isCompleteNfcCode(String? input) =>
    extractNfcCode(input)?.length == nfcCodeLength;

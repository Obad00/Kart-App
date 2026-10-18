/// Adresse interne générée pour un compte créé sans e-mail (inscription à
/// un événement avec le téléphone seul, cf. User::PLACEHOLDER_EMAIL_DOMAIN
/// côté backend). Ce n'est pas une vraie adresse : jamais proposée ni
/// affichée.
const kPlaceholderEmailDomain = 'kart-evenement.local';

bool isPlaceholderEmail(String? email) =>
    (email ?? '').trim().toLowerCase().endsWith('@$kPlaceholderEmailDomain');

/// L'e-mail à proposer, ou null s'il est vide ou interne.
String? displayableEmail(String? email) {
  final value = (email ?? '').trim();
  return value.isEmpty || isPlaceholderEmail(value) ? null : value;
}

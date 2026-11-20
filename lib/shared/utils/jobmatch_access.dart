/// JobMatch est fermé : KART se concentre sur les cartes et le networking.
/// Le code de lib/features/jobmatch reste en place mais n'est plus
/// accessible : barre du bas à 4 onglets (Carte, Contacts, Explorer,
/// Profil), liens kart://jobmatch et notifications JobMatch vers l'accueil.
/// Le backend ferme aussi la fonction (jobmatch.enabled = false).
///
/// Le paramètre [plan] est gardé pour ne pas retoucher les appels (index
/// des onglets calculés partout à partir de cette fonction).
bool canAccessJobMatch(String? plan) {
  return false;
}

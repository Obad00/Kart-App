/// JobMatch est désormais ouvert à tous les comptes, quel que soit le plan
/// (anciennement réservé au plan 'pro' — cf. historique git si besoin de
/// réintroduire une restriction). On garde cette fonction (plutôt que de
/// supprimer tous ses appels) pour ne pas avoir à retoucher la logique
/// d'affichage/index des onglets partout où elle est utilisée.
bool canAccessJobMatch(String? plan) {
  return true;
}

/// Libellé d'affichage d'un type de contrat — le champ est stocké en
/// minuscules côté backend (cf. le <select> de création d'offre côté CRM :
/// 'cdi', 'cdd', 'stage', 'freelance', 'alternance'), mais s'affichait tel
/// quel dans l'app ("cdd" au lieu de "CDD").
String contractTypeLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'cdi':
      return 'CDI';
    case 'cdd':
      return 'CDD';
    case 'stage':
      return 'Stage';
    case 'freelance':
      return 'Freelance';
    case 'alternance':
      return 'Alternance';
    default:
      // Valeur inconnue/future : au moins mettre une majuscule initiale
      // plutôt que de renvoyer la chaîne brute telle quelle.
      return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
  }
}

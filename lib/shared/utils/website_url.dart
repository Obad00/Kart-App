/// Adresse de site telle qu'on l'enregistre : « monsite.com » devient
/// « https://monsite.com ». Une adresse qui a déjà un protocole, ou un
/// champ vide, ne change pas. Même règle que le serveur
/// (`DigitalCardController::updateSummary`).
String completeWebsiteUrl(String value) {
  final url = value.trim();
  if (url.isEmpty || RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(url)) {
    return url;
  }
  return 'https://$url';
}

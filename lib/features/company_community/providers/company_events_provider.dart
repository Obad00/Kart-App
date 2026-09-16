import 'package:flutter/foundation.dart';

import '../../../shared/utils/safe_change_notifier.dart';
import '../models/company_event_summary.dart';
import '../services/company_community_service.dart';

/// Backe la section "Ma communauté" d'Explorer (compte entreprise
/// uniquement) — la liste des événements créés par l'entreprise. Échoue
/// silencieusement (liste vide) plutôt que de casser Explorer : un compte
/// entreprise sans le plan requis, ou dont le rôle ne donne pas accès à
/// /events, ne doit pas empêcher le reste de la page de s'afficher — même
/// logique que ExploreDiscoveryProvider pour les autres sections.
class CompanyEventsProvider extends SafeChangeNotifier {
  final CompanyCommunityService _service;

  CompanyEventsProvider(this._service);

  List<CompanyEventSummary> events = [];
  bool isLoading = false;
  bool _loaded = false;

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    isLoading = true;
    notifyListeners();

    try {
      events = await _service.fetchEvents();
    } catch (e) {
      debugPrint('❌ Erreur chargement des événements de l\'entreprise: $e');
      events = [];
    }

    _loaded = true;
    isLoading = false;
    notifyListeners();
  }
}

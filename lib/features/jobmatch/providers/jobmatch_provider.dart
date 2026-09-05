import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../model/job_feed_item.dart';
import '../model/job_filters.dart';
import '../services/jobmatch_service.dart';

class JobMatchProvider extends ChangeNotifier {
  final JobMatchService service;

  JobMatchProvider(this.service);

  List<JobFeedItem> feed = [];
  bool loading = false;
  String? error;
  JobMatchResult? lastMatch;
  JobMatchFilters filters = const JobMatchFilters();
  JobFilterOptions? filterOptions;

  /// Remet le provider à zéro à la déconnexion (cf. CardProvider.reset).
  void reset() {
    feed = [];
    loading = false;
    error = null;
    lastMatch = null;
    filters = const JobMatchFilters();
    filterOptions = null;
    notifyListeners();
  }

  Future<void> loadFeed() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      feed = await service.fetchFeed(filters: filters);
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible de charger les offres. Réessayez.');
    }

    loading = false;
    notifyListeners();
  }

  /// Chargées une seule fois (au premier ouverture de la feuille de
  /// filtres) — les valeurs disponibles (catégories, lieux...) ne changent
  /// pas assez souvent pour justifier un rechargement à chaque fois.
  Future<void> loadFilterOptions() async {
    if (filterOptions != null) return;
    try {
      filterOptions = await service.fetchFilterOptions();
      notifyListeners();
    } catch (_) {
      // silencieux : la feuille de filtres affichera juste des listes vides
    }
  }

  /// Applique une nouvelle sélection de filtres et recharge le fil.
  Future<void> applyFilters(JobMatchFilters newFilters) async {
    filters = newFilters;
    await loadFeed();
  }

  Future<void> swipe(JobFeedItem job, String action) async {
    feed = feed.where((j) => j.id != job.id).toList();
    notifyListeners();

    try {
      final match = await service.swipe(job.id, action);
      if (match != null) {
        lastMatch = match;
        notifyListeners();
      }
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible d\'enregistrer votre choix. Réessayez.');
      notifyListeners();
    }
  }

  void dismissMatch() {
    lastMatch = null;
    notifyListeners();
  }

  /// Sauvegarde/retire une offre pour plus tard — contrairement à swipe(),
  /// l'offre reste dans le feed (pas de matching, juste un marque-page).
  /// Optimiste (bascule l'état local avant la réponse serveur) avec retour
  /// en arrière silencieux en cas d'échec, comme le reste de l'app pour ce
  /// genre d'action à faible risque.
  Future<void> toggleSave(JobFeedItem job) async {
    final newValue = !job.isSaved;
    feed = feed
        .map((j) => j.id == job.id ? j.copyWithSaved(newValue) : j)
        .toList();
    notifyListeners();

    try {
      if (newValue) {
        await service.saveJob(job.id);
      } else {
        await service.unsaveJob(job.id);
      }
    } catch (e) {
      feed = feed
          .map((j) => j.id == job.id ? j.copyWithSaved(!newValue) : j)
          .toList();
      notifyListeners();
    }
  }
}

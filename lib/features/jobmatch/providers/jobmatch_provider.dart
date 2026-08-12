import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../model/job_feed_item.dart';
import '../services/jobmatch_service.dart';

class JobMatchProvider extends ChangeNotifier {
  final JobMatchService service;

  JobMatchProvider(this.service);

  List<JobFeedItem> feed = [];
  bool loading = false;
  String? error;
  JobMatchResult? lastMatch;

  /// Remet le provider à zéro à la déconnexion (cf. CardProvider.reset).
  void reset() {
    feed = [];
    loading = false;
    error = null;
    lastMatch = null;
    notifyListeners();
  }

  Future<void> loadFeed() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      feed = await service.fetchFeed();
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible de charger les offres. Réessayez.');
    }

    loading = false;
    notifyListeners();
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
}

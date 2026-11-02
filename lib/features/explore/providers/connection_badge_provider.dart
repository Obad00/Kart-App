import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_request_item.dart';
import '../services/explore_service.dart';

/// Compteur de demandes de connexion reçues en attente — affiché en badge
/// sur l'onglet Explorer. Séparé d'ExploreProvider (qui est page-scoped)
/// pour rester disponible dans la barre de navigation même quand la page
/// Explorer n'est pas ouverte.
///
/// Le dernier chiffre connu est gardé sur l'appareil : affiché dès
/// l'ouverture suivante de l'app (avant même la réponse du serveur), et
/// recopié sur l'icône de l'app (pastille iOS et Android).
class ConnectionBadgeProvider extends ChangeNotifier {
  static const prefsKey = 'pending_connection_requests_count';

  final ExploreService _service;

  ConnectionBadgeProvider({ExploreService? service}) : _service = service ?? ExploreService() {
    _restore();
  }

  int _pendingReceivedCount = 0;
  int get pendingReceivedCount => _pendingReceivedCount;

  Future<void> _restore() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getInt(prefsKey) ?? 0;
      // Une réponse du serveur arrivée entre-temps fait foi.
      if (saved != _pendingReceivedCount && _pendingReceivedCount == 0) {
        _pendingReceivedCount = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    try {
      final requests = await _service.fetchMyRequests(status: 'pending');
      final count = requests
          .where((r) => r.direction == RequestDirection.received)
          .length;
      await _set(count);
    } catch (_) {}
  }

  void clearBadge() {
    _set(0);
  }

  Future<void> _set(int count) async {
    if (count != _pendingReceivedCount) {
      _pendingReceivedCount = count;
      notifyListeners();
    }
    try {
      await (await SharedPreferences.getInstance()).setInt(prefsKey, count);
    } catch (_) {}
    try {
      // 0 retire la pastille de l'icône.
      await AppBadgePlus.updateBadge(count);
    } catch (_) {
      // Plateforme sans pastille (ou tests) : sans effet.
    }
  }
}

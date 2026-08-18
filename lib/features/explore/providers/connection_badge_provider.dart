import 'package:flutter/foundation.dart';
import '../models/connection_request_item.dart';
import '../services/explore_service.dart';

/// Compteur de demandes de connexion reçues en attente — affiché en badge
/// sur l'onglet Explorer. Séparé d'ExploreProvider (qui est page-scoped)
/// pour rester disponible dans la barre de navigation même quand la page
/// Explorer n'est pas ouverte.
class ConnectionBadgeProvider extends ChangeNotifier {
  final _service = ExploreService();

  int _pendingReceivedCount = 0;
  int get pendingReceivedCount => _pendingReceivedCount;

  Future<void> refresh() async {
    try {
      final requests = await _service.fetchMyRequests(status: 'pending');
      final count =
          requests.where((r) => r.direction == RequestDirection.received).length;
      if (count != _pendingReceivedCount) {
        _pendingReceivedCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearBadge() {
    if (_pendingReceivedCount == 0) return;
    _pendingReceivedCount = 0;
    notifyListeners();
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Suit l'état de la connexion réseau pour afficher un bandeau "Hors ligne"
/// — le cache disque (cf. ApiClient) fait le reste : les données déjà
/// chargées restent visibles, seules les actions réseau échouent.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
    } catch (_) {
      // Par défaut on suppose une connexion active plutôt que d'afficher
      // à tort un bandeau "Hors ligne" au démarrage.
    }
    notifyListeners();

    Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }
}

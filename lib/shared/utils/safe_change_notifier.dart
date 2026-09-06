import 'package:flutter/foundation.dart';

/// [ChangeNotifier] qui ignore silencieusement notifyListeners() après
/// dispose() au lieu de lancer une exception.
///
/// Une requête réseau lancée avant que la page ne soit quittée peut très
/// bien se résoudre après coup (navigation rapide pendant le chargement,
/// hot-reload/hot-restart en dev...) — appeler notifyListeners() à ce
/// moment-là ne veut rien dire de grave (il n'y a plus aucun listener à
/// prévenir), mais ChangeNotifier le traite comme une erreur fatale
/// ("A XProvider was used after being disposed"), qui plantait toute la
/// page.
class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

/// Gère les liens profonds au format `kart://...` (ex: bouton "Voir mes
/// offres likées" du mail d'intérêt candidat) — capte le lien qui a servi à
/// ouvrir l'app (cold start) et ceux reçus pendant qu'elle tourne déjà, et
/// navigue vers l'écran correspondant via [navigatorKey].
class DeepLinkService {
  DeepLinkService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  Future<void> init() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handle(initialLink);
    } catch (_) {
      // Ignorer : pas de lien initial ou plateforme non supportée.
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (_) {},
    );
  }

  void dispose() => _subscription?.cancel();

  void _handle(Uri uri) {
    if (uri.scheme != 'kart') return;

    // kart://jobmatch/liked — ouvre l'onglet "Aimées" du tableau de bord
    // JobMatch, depuis le mail envoyé quand un candidat like une offre.
    if (uri.host == 'jobmatch' && uri.pathSegments.contains('liked')) {
      _openLikedJobs();
    }
  }

  void _openLikedJobs() {
    // Attend que le premier frame soit posé (cas cold start, où l'app vient
    // tout juste de démarrer) avant de naviguer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'tab': 3, 'openLikedJobs': true},
      );
    });
  }
}

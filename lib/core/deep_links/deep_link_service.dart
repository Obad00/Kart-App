import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../shared/utils/jobmatch_access.dart';

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

    if (uri.host == 'explore' && uri.pathSegments.contains('requests')) {
      // kart://explore/requests — bouton unique du mail de demande de
      // connexion (remplace les anciens liens Accepter/Refuser) : ouvre
      // directement l'onglet "Mes demandes" dans l'app.
      _openExploreRequests();
      return;
    }

    if (uri.host != 'jobmatch') return;

    // kart://jobmatch/liked — mail envoyé quand un candidat like une offre.
    if (uri.pathSegments.contains('liked')) {
      _openDashboard(tabIndex: 1); // Aimées
      return;
    }

    // kart://jobmatch/matches — mail envoyé quand un match se crée.
    if (uri.pathSegments.contains('matches')) {
      _openDashboard(tabIndex: 0); // Matchs
      return;
    }

    // kart://jobmatch (sans chemin) — mail envoyé quand une entreprise
    // like un candidat qui n'a pas encore liké l'offre : pas de tableau de
    // bord à ouvrir spécifiquement (pas encore de match/like), juste le
    // fil d'offres où il peut la retrouver et l'aimer.
    _openFeedTab();
  }

  void _openExploreRequests() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      final context = _navigatorKey.currentContext;
      if (navigator == null || context == null) return;

      final showJobMatch = canAccessJobMatch(
        context.read<AuthProvider>().user?.plan,
      );
      navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {
          'tab': showJobMatch ? 3 : 2, // Explorer
          'openExploreTab': 1, // Mes demandes
        },
      );
    });
  }

  /// [tabIndex] : onglet du tableau de bord JobMatch à ouvrir (0 = Matchs,
  /// 1 = Aimées, 2 = Passées).
  void _openDashboard({required int tabIndex}) {
    // Attend que le premier frame soit posé (cas cold start, où l'app vient
    // tout juste de démarrer) avant de naviguer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        // Onglet "Offres" (JobMatch) : index 2 depuis le retrait de Scan de
        // la barre du bas (Carte=0, Contacts=1, Offres=2, Explorer=3, Profil=4).
        arguments: {'tab': 2, 'openDashboardTab': tabIndex},
      );
    });
  }

  void _openFeedTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'tab': 2}, // Offres
      );
    });
  }
}

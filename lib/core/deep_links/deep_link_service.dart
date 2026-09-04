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
    _navigateWhenReady((context, navigator) {
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
    _navigateWhenReady((context, navigator) {
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
    _navigateWhenReady((context, navigator) {
      navigator.pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'tab': 2}, // Offres
      );
    });
  }

  /// Attend le premier frame (cas cold start) PUIS la fin de l'init de
  /// [AuthProvider] avant d'exécuter [action] — sur un lien reçu au tout
  /// lancement de l'app, ce handler s'exécutait plus vite que
  /// AuthProvider._init() (qui va chercher /me en réseau) : on poussait déjà
  /// '/home' avec AuthProvider.user encore à null, et HomeShell (qui se fie
  /// à auth.isAuthenticated) renvoyait aussitôt vers /login — alors que la
  /// session était en fait valide, juste pas encore chargée. D'où le "il me
  /// demande de me reconnecter" alors que l'utilisateur était bien connecté.
  /// Si la session s'avère réellement absente une fois l'init terminée, on
  /// laisse simplement le flux normal (SplashScreen → /login) suivre son
  /// cours plutôt que de forcer '/home'.
  void _navigateWhenReady(
    void Function(BuildContext context, NavigatorState navigator) action,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _navigatorKey.currentContext;
      if (context == null) return;

      await context.read<AuthProvider>().waitForInit();

      // Ré-obtenus après l'await : ce ne sont pas les mêmes objets qu'avant
      // le gap async (le lint ne peut pas le savoir faute de `mounted`,
      // indisponible hors d'un State).
      final navigator = _navigatorKey.currentState;
      final readyContext = _navigatorKey.currentContext;
      if (navigator == null || readyContext == null) return;
      // ignore: use_build_context_synchronously
      if (!readyContext.read<AuthProvider>().isAuthenticated) return;

      // ignore: use_build_context_synchronously
      action(readyContext, navigator);
    });
  }
}

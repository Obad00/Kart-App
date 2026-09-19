import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/utils/safe_change_notifier.dart';
import '../models/connection_request_item.dart';
import '../models/explore_user.dart';
import '../services/explore_service.dart';

class ExploreProvider extends SafeChangeNotifier {
  final ExploreService _service;

  // 'recommended' (défaut, classement par complétion) | 'certified' |
  // 'new' | 'sector' | 'near' | 'weekly' — cf. ExploreController::index()
  // côté backend. Une instance par carrousel de la page Explorer
  // (refonte) : même provider, juste une section différente.
  final String section;
  // Nom d'un secteur JobSectors ("Tech & Digital"...) — "Explorer par
  // catégorie", indépendant de section.
  final String category;

  ExploreProvider(this._service,
      {this.section = 'recommended', this.category = ''});

  List<ExploreUser> users = [];
  List<String> jobTitles = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? error;
  int _page = 1;
  String _search = '';
  String _jobTitleFilter = '';
  String get jobTitleFilter => _jobTitleFilter;

  // Requête en cours : annulée dès qu'une nouvelle recherche la remplace.
  // Sans ça, une requête plus ancienne qui échoue (réseau lent, frappe en
  // rafale) écrasait le résultat de la plus récente par un message
  // d'erreur — remonté côté produit : "dès que je commence à taper on me
  // dit impossible de charger les profils".
  CancelToken? _loadToken;

  Future<void> loadUsers({String? search, String? jobTitle}) async {
    _search = search ?? _search;
    _jobTitleFilter = jobTitle ?? _jobTitleFilter;
    _page = 1;

    _loadToken?.cancel('remplacée par une recherche plus récente');
    final token = CancelToken();
    _loadToken = token;

    // On garde les profils déjà affichés pendant le rechargement : la
    // recherche se contente de les remplacer une fois arrivée, au lieu de
    // vider l'écran puis de le remplir (impression de lenteur à chaque
    // frappe).
    isLoading = users.isEmpty;
    error = null;
    notifyListeners();

    try {
      final result = await _service.fetchUsers(
        page: _page,
        search: _search,
        jobTitle: _jobTitleFilter,
        section: section,
        category: category,
        cancelToken: token,
      );
      users = result.users;
      hasMore = result.hasMore;
      // La liste des postes ne change pas selon la page/recherche en
      // cours côté serveur — on la garde une fois récupérée pour éviter
      // que les chips ne disparaissent en filtrant.
      if (result.jobTitles.isNotEmpty) jobTitles = result.jobTitles;
    } on DioException catch (e) {
      // Annulation volontaire (frappe suivante) : ni erreur ni fin de
      // chargement, la requête qui l'a remplacée s'en charge.
      if (CancelToken.isCancel(e)) return;

      debugPrint(
          '❌ Erreur loadUsers (explore): ${e.response?.statusCode} ${e.message}');
      error = _messageFor(e);
    } catch (e) {
      debugPrint('❌ Erreur loadUsers (explore): $e');
      error = 'Impossible de charger les profils.';
    }

    if (_loadToken != token) return;
    isLoading = false;
    notifyListeners();
  }

  /// Message qui dit ce qui s'est réellement passé plutôt qu'un
  /// "Impossible de charger les profils" systématique — sans ça, un 500
  /// côté serveur, une session expirée et une coupure réseau étaient
  /// impossibles à distinguer depuis l'app comme depuis un rapport de bug.
  String _messageFor(DioException e) {
    final status = e.response?.statusCode;

    if (status == null) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (status == 401 || status == 403) {
      return 'Session expirée. Reconnectez-vous pour continuer.';
    }
    if (status >= 500) {
      return 'Le serveur a rencontré une erreur ($status). Réessayez dans un instant.';
    }

    return 'Impossible de charger les profils ($status).';
  }

  void setJobTitleFilter(String jobTitle) {
    loadUsers(jobTitle: jobTitle);
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchUsers(
        page: _page + 1,
        search: _search,
        jobTitle: _jobTitleFilter,
        section: section,
        category: category,
      );
      users = [...users, ...result.users];
      hasMore = result.hasMore;
      _page++;
    } catch (e) {
      debugPrint('❌ Erreur loadMore (explore): $e');
    }

    isLoadingMore = false;
    notifyListeners();
  }

  /// Retire un profil de la liste de découverte — utilisé après avoir
  /// accepté/refusé une demande reçue depuis cette liste (le widget
  /// ConnectActionButton gère l'appel réseau lui-même, ce provider ne
  /// gère plus que l'état de la liste).
  void removeUserLocally(int userId) {
    users = users.where((u) => u.id != userId).toList();
    notifyListeners();
  }

  /// Synchronise le statut de connexion d'un profil affiché ici — remonté
  /// côté produit : envoyer/annuler une demande depuis la fiche détail
  /// (PublicCardPage) d'un profil ne se répercutait pas sur son bouton
  /// dans cette liste (deux instances de ConnectActionButton, chacune avec
  /// son propre état interne). Voir ConnectActionButton.onStatusChanged.
  void updateUserConnection(int userId, ConnectionStatus status, int? requestId) {
    users = users.map((u) {
      if (u.id != userId) return u;
      return status == ConnectionStatus.none
          ? u.clearConnection()
          : u.copyWith(connectionStatus: status, connectionRequestId: requestId);
    }).toList();
    notifyListeners();
  }

  // ───────────────── Onglet "Mes demandes" ─────────────────
  List<ConnectionRequestItem> myRequests = [];
  bool isLoadingMyRequests = false;
  String myRequestsStatusFilter = 'all';

  Future<void> loadMyRequests({String? status}) async {
    myRequestsStatusFilter = status ?? myRequestsStatusFilter;
    isLoadingMyRequests = true;
    notifyListeners();

    try {
      myRequests =
          await _service.fetchMyRequests(status: myRequestsStatusFilter);
    } catch (e) {
      debugPrint('❌ Erreur loadMyRequests (explore): $e');
    }

    isLoadingMyRequests = false;
    notifyListeners();
  }

  /// Répond à une demande reçue depuis l'onglet "Mes demandes" — met à jour
  /// son statut localement DANS CETTE LISTE au lieu de la faire disparaître
  /// (utile ici pour voir tout de suite le résultat), mais retire bien le
  /// profil correspondant de la liste de découverte Explorer (voir plus bas).
  ///
  /// Retourne un message d'erreur en cas d'échec (à afficher par l'appelant,
  /// ex: SnackBar) ou `null` en cas de succès — sans ça, un échec réseau/
  /// serveur ne montrait rien à l'utilisateur ("j'accepte et rien ne se
  /// passe").
  Future<String?> respondFromMyRequests(int requestId, String action) async {
    try {
      await _service.respond(requestId, action);
    } catch (e) {
      return e is DioException
          ? ((e.response?.data is Map
                  ? (e.response?.data as Map)['message']?.toString()
                  : null) ??
              'Une erreur est survenue, réessayez.')
          : 'Une erreur est survenue, réessayez.';
    }

    ExploreUser? otherUser;
    myRequests = myRequests
        .map((r) {
          if (r.id != requestId) return r;
          otherUser = r.otherUser;
          return ConnectionRequestItem(
            id: r.id,
            direction: r.direction,
            status: action == 'accept' ? 'accepted' : 'declined',
            createdAt: r.createdAt,
            otherUser: r.otherUser,
          );
        })
        .toList();

    // Sans ça, accepter/refuser ici ne se répercutait pas sur la liste
    // Explorer (l'app devait être relancée pour que le profil en disparaisse)
    // — même correctif que ConnectActionButton._respond(), qui retire déjà
    // la carte de la liste via onResolved/removeUserLocally dans les deux
    // cas (accepter ET refuser) quand la résolution se fait depuis cette
    // liste-là. Accepter crée un contact — le backend exclut déjà les
    // contacts de /api/explore, donc le profil n'y réapparaîtra pas même
    // après un vrai rafraîchissement.
    if (otherUser != null) {
      removeUserLocally(otherUser!.id);
    }

    notifyListeners();
    return null;
  }

  void reset() {
    users = [];
    jobTitles = [];
    isLoading = false;
    isLoadingMore = false;
    hasMore = true;
    error = null;
    _page = 1;
    _search = '';
    _jobTitleFilter = '';
    myRequests = [];
    isLoadingMyRequests = false;
    myRequestsStatusFilter = 'all';
    notifyListeners();
  }
}

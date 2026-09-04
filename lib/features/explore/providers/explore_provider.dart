import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/connection_request_item.dart';
import '../models/explore_user.dart';
import '../services/explore_service.dart';

class ExploreProvider extends ChangeNotifier {
  final ExploreService _service;

  // 'recommended' (défaut, classement par complétion) | 'certified' |
  // 'new' | 'sector' | 'near' | 'weekly' — cf. ExploreController::index()
  // côté backend. Une instance par carrousel de la page Explorer
  // (refonte) : même provider, juste une section différente.
  final String section;
  // Nom d'un secteur JobSectors ("Tech & Digital"...) — "Explorer par
  // catégorie", indépendant de section.
  final String category;

  ExploreProvider(this._service, {this.section = 'recommended', this.category = ''});

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

  Future<void> loadUsers({String? search, String? jobTitle}) async {
    _search = search ?? _search;
    _jobTitleFilter = jobTitle ?? _jobTitleFilter;
    _page = 1;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _service.fetchUsers(
        page: _page,
        search: _search,
        jobTitle: _jobTitleFilter,
        section: section,
        category: category,
      );
      users = result.users;
      hasMore = result.hasMore;
      // La liste des postes ne change pas selon la page/recherche en
      // cours côté serveur — on la garde une fois récupérée pour éviter
      // que les chips ne disparaissent en filtrant.
      if (result.jobTitles.isNotEmpty) jobTitles = result.jobTitles;
    } catch (e) {
      debugPrint('❌ Erreur loadUsers (explore): $e');
      error = 'Impossible de charger les profils.';
    }

    isLoading = false;
    notifyListeners();
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

  /// Répond à une demande reçue depuis l'onglet "Mes demandes" — met à
  /// jour son statut localement au lieu de la faire disparaître (utile ici
  /// pour voir tout de suite le résultat, contrairement à la liste de
  /// découverte).
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

    myRequests = myRequests
        .map((r) => r.id == requestId
            ? ConnectionRequestItem(
                id: r.id,
                direction: r.direction,
                status: action == 'accept' ? 'accepted' : 'declined',
                createdAt: r.createdAt,
                otherUser: r.otherUser,
              )
            : r)
        .toList();
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

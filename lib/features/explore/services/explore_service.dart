import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/connection_request_item.dart';
import '../models/explore_category.dart';
import '../models/explore_user.dart';

class ExploreService {
  /// "Explorer par catégorie" — cf. ExploreController::categories().
  Future<List<ExploreCategory>> fetchCategories() async {
    final response = await ApiClient.dio.get('/explore/categories');
    return (response.data['data'] as List)
        .map((e) => ExploreCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<ExploreUser> users, bool hasMore, List<String> jobTitles})>
      fetchUsers({
    required int page,
    String search = '',
    String jobTitle = '',
    // 'recommended' | 'certified' | 'new' | 'sector' | 'near' | 'weekly' —
    // cf. ExploreController::index().
    String section = 'recommended',
    // Nom d'un secteur JobSectors ("Tech & Digital"...) — "Explorer par
    // catégorie" (tap sur une case), indépendant de section.
    String category = '',
    CancelToken? cancelToken,
  }) async {
    final response = await ApiClient.dio.get(
      '/explore',
      queryParameters: {
        'page': page,
        if (search.isNotEmpty) 'search': search,
        if (jobTitle.isNotEmpty) 'job_title': jobTitle,
        if (section != 'recommended') 'section': section,
        if (category.isNotEmpty) 'category': category,
      },
      cancelToken: cancelToken,
    );

    // `as List` sec sur une réponse inattendue (corps vide servi par le
    // cache hors-ligne, page d'erreur HTML d'un proxy...) faisait remonter
    // un TypeError présenté comme "Impossible de charger les profils" :
    // une réponse sans 'data' exploitable vaut mieux comme liste vide.
    final data = response.data;
    final rawList = (data is Map ? data['data'] : null) as List? ?? const [];
    final list = rawList
        .whereType<Map<String, dynamic>>()
        .map(ExploreUser.fromJson)
        .toList();

    final currentPage =
        (data is Map ? data['current_page'] : null) as int? ?? page;
    final lastPage = (data is Map ? data['last_page'] : null) as int? ?? page;
    final jobTitles =
        ((data is Map ? data['jobTitles'] : null) as List? ?? const [])
            .map((e) => e.toString())
            .toList();

    return (users: list, hasMore: currentPage < lastPage, jobTitles: jobTitles);
  }

  /// Onglet "Mes demandes" — [status] : null/'all', 'pending', 'accepted' ou 'declined'.
  Future<List<ConnectionRequestItem>> fetchMyRequests({String? status}) async {
    final response =
        await ApiClient.dio.get('/connection-requests', queryParameters: {
      if (status != null && status != 'all') 'status': status,
    });

    return (response.data['data'] as List)
        .map((e) => ConnectionRequestItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Retourne l'id de la demande créée — utilisé pour permettre d'accepter/
  /// refuser directement dans l'app sans recharger toute la liste.
  Future<int?> connect(int userId) async {
    final response = await ApiClient.dio.post('/explore/$userId/connect');
    final id = response.data?['request']?['id'];
    return id != null ? int.tryParse(id.toString()) : null;
  }

  /// Accepte/refuse une demande directement dans l'app (même résultat que
  /// les liens du mail) — [action] : 'accept' ou 'decline'.
  Future<void> respond(int requestId, String action) async {
    await ApiClient.dio.post('/connection-requests/$requestId/$action');
  }

  /// Annule une demande envoyée encore en attente.
  Future<void> cancel(int requestId) async {
    await ApiClient.dio.delete('/connection-requests/$requestId');
  }
}

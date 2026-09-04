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
    // 'recommended' | 'certified' | 'new' | 'sector' | 'near' — cf.
    // ExploreController::index().
    String section = 'recommended',
  }) async {
    final response = await ApiClient.dio.get('/explore', queryParameters: {
      'page': page,
      if (search.isNotEmpty) 'search': search,
      if (jobTitle.isNotEmpty) 'job_title': jobTitle,
      if (section != 'recommended') 'section': section,
    });

    final data = response.data;
    final list = (data['data'] as List)
        .map((e) => ExploreUser.fromJson(e as Map<String, dynamic>))
        .toList();

    final currentPage = data['current_page'] as int? ?? page;
    final lastPage = data['last_page'] as int? ?? page;
    final jobTitles =
        (data['jobTitles'] as List? ?? []).map((e) => e.toString()).toList();

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

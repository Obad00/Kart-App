import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/job_feed_item.dart';
import '../model/job_filters.dart';

class JobMatchService {
  final Dio dio = ApiClient.dio;

  Future<List<JobFeedItem>> fetchFeed({JobMatchFilters? filters}) async {
    final res = await dio.get(
      ApiEndpoints.jobMatchFeed,
      queryParameters: filters?.toQueryParams(),
    );
    final list = res.data['feed'] as List;
    return list.map((e) => JobFeedItem.fromJson(e)).toList();
  }

  Future<JobFilterOptions> fetchFilterOptions() async {
    final res = await dio.get(ApiEndpoints.jobMatchFilterOptions);
    return JobFilterOptions.fromJson(res.data);
  }

  Future<JobMatchResult?> swipe(int jobId, String action) async {
    final res = await dio.post(
      ApiEndpoints.jobMatchSwipe(jobId),
      data: {'action': action},
    );
    final matchJson = res.data['match'];
    return matchJson == null ? null : JobMatchResult.fromJson(matchJson);
  }

  Future<List<JobMatchResult>> fetchMatches() async {
    final res = await dio.get(ApiEndpoints.jobMatchMatches);
    final list = res.data['matches'] as List;
    return list.map((e) => JobMatchResult.fromJson(e)).toList();
  }

  Future<List<LikedJobItem>> fetchLiked() async {
    final res = await dio.get(ApiEndpoints.jobMatchLiked);
    final list = res.data['liked'] as List;
    return list.map((e) => LikedJobItem.fromJson(e)).toList();
  }

  Future<JobMatchSummary> fetchSummary() async {
    final res = await dio.get(ApiEndpoints.jobMatchSummary);
    return JobMatchSummary.fromJson(res.data);
  }

  Future<List<LikedJobItem>> fetchRejected() async {
    final res = await dio.get(ApiEndpoints.jobMatchRejected);
    final list = res.data['rejected'] as List;
    return list.map((e) => LikedJobItem.fromJson(e)).toList();
  }

  /// Annule un rejet — l'offre réapparaît dans le feed principal.
  Future<void> unswipe(int jobId) async {
    await dio.delete(ApiEndpoints.jobMatchSwipe(jobId));
  }

  /// Sauvegarder/retirer une offre — distinct d'un like : ne retire pas
  /// l'offre du feed et ne déclenche aucun matching.
  Future<void> saveJob(int jobId) async {
    await dio.post(ApiEndpoints.jobMatchSave(jobId));
  }

  Future<void> unsaveJob(int jobId) async {
    await dio.delete(ApiEndpoints.jobMatchSave(jobId));
  }

  Future<List<LikedJobItem>> fetchSaved() async {
    final res = await dio.get(ApiEndpoints.jobMatchSaved);
    final list = res.data['saved'] as List;
    return list.map((e) => LikedJobItem.fromJson(e)).toList();
  }
}

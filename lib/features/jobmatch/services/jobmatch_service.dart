import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/job_feed_item.dart';

class JobMatchService {
  final Dio dio = ApiClient.dio;

  Future<List<JobFeedItem>> fetchFeed() async {
    final res = await dio.get(ApiEndpoints.jobMatchFeed);
    final list = res.data['feed'] as List;
    return list.map((e) => JobFeedItem.fromJson(e)).toList();
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
}

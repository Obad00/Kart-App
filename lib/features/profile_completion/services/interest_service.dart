import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/interest_model.dart';

/// Recherche/autocomplete dans le référentiel de centres d'intérêt — même
/// principe que CandidateSkillsService.search().
class InterestService {
  final Dio dio = ApiClient.dio;

  Future<List<InterestSuggestion>> search(String query) async {
    final res = await dio.get('/interests', queryParameters: {
      if (query.isNotEmpty) 'search': query,
    });
    final list = res.data as List;
    return list.map((e) => InterestSuggestion.fromJson(e)).toList();
  }
}

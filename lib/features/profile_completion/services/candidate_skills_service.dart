import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/skill_model.dart';

class CandidateSkillsService {
  final Dio dio = ApiClient.dio;

  Future<List<CandidateSkillModel>> fetch() async {
    final res = await dio.get('/candidate/skills');
    final list = res.data['skills'] as List;
    return list.map((e) => CandidateSkillModel.fromJson(e)).toList();
  }

  Future<List<CandidateSkillModel>> update(
    List<CandidateSkillModel> skills,
  ) async {
    final res = await dio.put(
      '/candidate/skills',
      data: {'skills': skills.map((s) => s.toPayload()).toList()},
    );
    final list = res.data['skills'] as List;
    return list.map((e) => CandidateSkillModel.fromJson(e)).toList();
  }

  Future<List<SkillSuggestion>> search(String query, {String? category}) async {
    final res = await dio.get('/skills', queryParameters: {
      if (query.isNotEmpty) 'search': query,
      if (category != null) 'category': category,
    });
    final list = res.data as List;
    return list.map((e) => SkillSuggestion.fromJson(e)).toList();
  }
}

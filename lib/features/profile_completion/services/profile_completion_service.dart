import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../model/profile_completion_model.dart';

class ProfileCompletionService {
  final Dio dio = ApiClient.dio;

  Future<ProfileCompletionModel> fetch() async {
    final res = await dio.get('/me/card-summary');

    return ProfileCompletionModel.fromJson(res.data);
  }

  Future<bool> update(ProfileCompletionModel model) async {
    await dio.put(
      '/me/card-summary',
      data: model.toJson(),
    );

    return true;
  }
}

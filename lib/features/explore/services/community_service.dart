import '../../../core/network/api_client.dart';
import '../models/community.dart';

class CommunityService {
  Future<List<Community>> fetchCommunities() async {
    final response = await ApiClient.dio.get('/communities');
    return (response.data['data'] as List)
        .map((e) => Community.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> join(int communityId) async {
    final response = await ApiClient.dio.post('/communities/$communityId/join');
    return int.tryParse(response.data?['membersCount']?.toString() ?? '') ?? 0;
  }

  Future<int> leave(int communityId) async {
    final response =
        await ApiClient.dio.delete('/communities/$communityId/leave');
    return int.tryParse(response.data?['membersCount']?.toString() ?? '') ?? 0;
  }
}

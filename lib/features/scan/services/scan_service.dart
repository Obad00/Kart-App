import '../../../core/network/api_client.dart';

class ScanService {
  Future<Map<String, dynamic>> scanCard(String slug) async {
    final response = await ApiClient.dio.post(
      '/cards/$slug/scan',
    );

    return response.data;
  }
}

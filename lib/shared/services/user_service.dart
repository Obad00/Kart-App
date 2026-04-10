import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

class UserService {
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data;
  }
}

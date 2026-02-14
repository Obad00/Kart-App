import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PublicCardService {
  // Accès direct au Dio statique
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>> fetchCard(String slug) async {
    final response = await _dio.get('/cards/$slug');
    return response.data;
  }
}

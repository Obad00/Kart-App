import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PlanService {
  final Dio _dio = ApiClient.dio;

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    final res = await _dio.get('/plans');
    if (res.data is List) return List<Map<String, dynamic>>.from(res.data);
    throw Exception('Format de réponse invalide');
  }

  Future<int> subscribePlan(int planId) async {
    final res = await _dio.post('/subscriptions/subscribe', data: {'plan_id': planId});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return res.data['subscription']['id'];
    }
    throw Exception('Erreur lors de la souscription');
  }
}

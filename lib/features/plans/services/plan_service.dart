import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class FreePlanActivationResponse {
  final int statusCode;
  final Map<String, dynamic> data;

  FreePlanActivationResponse({
    required this.statusCode,
    required this.data,
  });
}

class PlanService {
  final Dio _dio = ApiClient.dio;

  Future<List<Map<String, dynamic>>> fetchPlans() async {
    final res = await _dio.get('/plans');
    debugPrint('📦 Plans Response: \\${res.data}');
    if (res.data is List) return List<Map<String, dynamic>>.from(res.data);
    throw Exception('Format de réponse invalide');
  }

  Future<int> subscribePlan(int planId) async {
    final res =
        await _dio.post('/subscriptions/subscribe', data: {'plan_id': planId});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return res.data['subscription']['id'];
    }
    throw Exception('Erreur lors de la souscription');
  }

  Future<FreePlanActivationResponse> activateFreePlan(String planSlug) async {
    final res = await _dio.post(
      ApiEndpoints.activateFreePlan,
      data: {'plan_slug': planSlug},
      options: Options(
        // We need to inspect 4xx responses (validation, verification, etc.) in UI flow.
        validateStatus: (_) => true,
      ),
    );

    final payload = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{
            'success': false,
            'message': 'Réponse serveur invalide',
          };

    debugPrint(
      '🧩 activateFreePlan status=${res.statusCode} payload=$payload',
    );

    return FreePlanActivationResponse(
      statusCode: res.statusCode ?? 0,
      data: payload,
    );
  }
}

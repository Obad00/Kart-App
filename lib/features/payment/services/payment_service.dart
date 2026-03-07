import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/plan.dart';
import '../models/payment_method.dart';
import '../models/payment.dart';

class PaymentService {
  final Dio _dio = ApiClient.dio;

  Future<List<Plan>> fetchPlans() async {
    final response = await _dio.get(ApiEndpoints.plans);
    if (response.data is List) {
      return (response.data as List)
          .map((json) => Plan.fromJson(json))
          .toList();
    }
    throw Exception('Format de réponse invalide');
  }

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await _dio.get(ApiEndpoints.paymentMethods);
    final methods = response.data['methods'] as List;
    return methods.map((json) => PaymentMethod.fromJson(json)).toList();
  }

  Future<PaymentInitResult> initializePayment({
    required int planId,
    required String paymentMethod,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.paymentInitialize,
      data: {
        'plan_id': planId,
        'payment_method': paymentMethod,
      },
    );

    if (response.data['success'] == true) {
      return PaymentInitResult(
        success: true,
        reference: response.data['reference'],
        paymentUrl: response.data['payment_url'],
        plan: Plan.fromJson(response.data['plan']),
      );
    }

    return PaymentInitResult(
      success: false,
      message: response.data['message'] ?? 'Erreur lors de l\'initialisation',
    );
  }

  Future<Payment> checkPaymentStatus(String reference) async {
    final response = await _dio.get(ApiEndpoints.paymentStatus(reference));
    return Payment.fromJson(response.data['payment']);
  }

  Future<List<Payment>> fetchPaymentHistory({int page = 1}) async {
    final response = await _dio.get(
      ApiEndpoints.paymentHistory,
      queryParameters: {'page': page},
    );
    final data = response.data['data'] as List;
    return data.map((json) => Payment.fromJson(json)).toList();
  }
}

class PaymentInitResult {
  final bool success;
  final String? reference;
  final String? paymentUrl;
  final Plan? plan;
  final String? message;

  PaymentInitResult({
    required this.success,
    this.reference,
    this.paymentUrl,
    this.plan,
    this.message,
  });
}

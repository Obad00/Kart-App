import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class ScanService {
  Future<Map<String, dynamic>> scanCard(String slug) async {
    try {
      final response = await ApiClient.dio.post(
        '/cards/$slug/scan',
      );

      return {
        'statusCode': response.statusCode,
        'message': response.data['message'],
        'data': response.data['contact'],
      };
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message =
          e.response?.data['message'] ?? 'Erreur lors du scan';

      throw ScanException(
        message: message,
        statusCode: statusCode,
      );
    }
  }
}

class ScanException implements Exception {
  final String message;
  final int? statusCode;

  ScanException({
    required this.message,
    this.statusCode,
  });
}

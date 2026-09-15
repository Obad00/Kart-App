import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Scan du QR de check-in affiché à l'accueil d'un événement — un seul
/// endpoint pour tout le monde (cf. EventPublicController::checkin() côté
/// backend) : appelé depuis l'app avec le jeton d'authentification habituel
/// de ApiClient.dio, il enregistre directement la présence sur le compte
/// connecté (jamais de walk-in ici, réservé à un scan hors app/déconnecté).
class EventCheckinService {
  Future<Map<String, dynamic>> checkin(String slug) async {
    try {
      final response = await ApiClient.dio.post('/events/$slug/checkin');

      return {
        'event': response.data['event'],
        'checked_in_at': response.data['checked_in_at'],
      };
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;

      throw EventCheckinException(
        message: message ?? 'Impossible d\'enregistrer votre présence.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class EventCheckinException implements Exception {
  final String message;
  final int? statusCode;

  EventCheckinException({required this.message, this.statusCode});
}

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

  /// Check-in d'UN AUTRE participant par un collaborateur de l'entreprise
  /// qui scanne SA carte personnelle — distinct de checkin() ci-dessus, qui
  /// marque le compte connecté (le scanneur) présent. Ici c'est la carte
  /// scannée qui identifie qui marquer présent (cf.
  /// EventController::checkinByCard() côté backend).
  Future<Map<String, dynamic>> checkinByCard(int eventId, String cardSlug) async {
    try {
      final response = await ApiClient.dio.post(
        '/events/$eventId/checkin-by-card',
        data: {'card_slug': cardSlug},
      );

      return {
        'already_present': response.data['already_present'] == true,
        'user': response.data['user'],
        'checked_in_at': response.data['checked_in_at'],
      };
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;

      throw EventCheckinException(
        message: message ?? "Impossible d'enregistrer cette présence.",
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Check-in via le QR PERSONNEL imprimé sur le badge d'un participant
  /// (cf. Event::badgeCheckinUrl() côté backend) — le jeton identifie déjà
  /// la ligne de présence, donc rien d'autre à fournir. Endpoint public
  /// (le jeton fait foi) mais appelé ici avec la session du collaborateur :
  /// remonté côté produit, scanner le badge téléchargé doit marquer présent
  /// aussi bien que scanner la carte de visite.
  Future<Map<String, dynamic>> checkinByBadge(String slug, String token) async {
    try {
      final response = await ApiClient.dio.post(
        '/events/$slug/badge/$token/checkin',
      );

      return {
        'already_present': response.data['already_checked_in'] == true,
        'user': {'name': response.data['participant_name']},
        'checked_in_at': response.data['checked_in_at'],
      };
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;

      throw EventCheckinException(
        message: message ?? "Impossible d'enregistrer cette présence.",
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

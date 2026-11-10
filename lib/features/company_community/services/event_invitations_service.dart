import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/event_invitation.dart';

/// Invitations WhatsApp d'un événement : mêmes routes que le CRM du site
/// (cf. EventInvitationController), plus l'ajout en lot depuis les contacts.
/// Le téléphone est envoyé tel quel : c'est le backend qui le normalise.
class EventInvitationsService {
  String _base(int eventId) => '/events/$eventId/invitations';

  Future<InvitationPage> list(
    int eventId, {
    InvitationStatus? status,
    String? category,
    String? query,
    int page = 1,
    CancelToken? cancelToken,
  }) async {
    final response = await ApiClient.dio
        .get(_base(eventId), cancelToken: cancelToken, queryParameters: {
      'page': page,
      'per_page': 50,
      if (status != null) 'status': status.api,
      if (category != null && category.isNotEmpty) 'category': category,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    });
    return InvitationPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EventInvitation> create(
    int eventId, {
    required String name,
    required String phone,
    String? email,
    String? category,
    String? standNumber,
  }) async {
    final response = await ApiClient.dio.post(_base(eventId), data: {
      'name': name,
      'phone': phone,
      'email': email,
      'category': category,
      'stand_number': standNumber,
    });
    return EventInvitation.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<EventInvitation> createHonor(
    int eventId, {
    required String civility,
    required String name,
    required String honorMessage,
    String? guestTitle,
    String? phone,
  }) async {
    final response = await ApiClient.dio.post('${_base(eventId)}/honor', data: {
      'civility': civility,
      'name': name,
      'guest_title': guestTitle,
      'phone': phone,
      'honor_message': honorMessage,
    });
    return EventInvitation.fromJson({
      ...(response.data['data'] as Map<String, dynamic>),
      'created': response.data['created'],
    });
  }

  Future<EventInvitation> update(
    int eventId,
    int invitationId, {
    required String name,
    required String phone,
    String? email,
    String? category,
    String? standNumber,
  }) async {
    final response =
        await ApiClient.dio.patch('${_base(eventId)}/$invitationId', data: {
      'name': name,
      'phone': phone,
      'email': email,
      'category': category,
      'stand_number': standNumber,
    });
    return EventInvitation.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<EventInvitation> updateHonor(
    int eventId,
    int invitationId, {
    required String civility,
    required String name,
    required String honorMessage,
    String? guestTitle,
    String? phone,
  }) async {
    final response =
        await ApiClient.dio.patch('${_base(eventId)}/$invitationId', data: {
      'civility': civility,
      'name': name,
      'guest_title': guestTitle,
      'phone': phone,
      'honor_message': honorMessage,
    });
    return EventInvitation.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<String> uploadPhoto(
      int eventId, int invitationId, Uint8List bytes, String filename) async {
    final response = await ApiClient.dio.post(
      '${_base(eventId)}/$invitationId/photo',
      data: FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final url = response.data['data']['photo_url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('La réponse ne contient pas la photo.');
    }
    return url;
  }

  Future<void> removePhoto(int eventId, int invitationId) async {
    await ApiClient.dio.delete('${_base(eventId)}/$invitationId/photo');
  }

  Future<Map<String, String>> honorDefaultMessages(int eventId) async {
    final response =
        await ApiClient.dio.get('/events/$eventId/invitation-settings');
    final messages = (response.data['data']['honor_default_messages'] as Map?)
            ?.cast<String, dynamic>() ??
        {};
    return messages.map((key, value) => MapEntry(key, value as String));
  }

  /// Catégories existantes et catégories d'exposants (liste déroulante du
  /// formulaire et de l'ajout depuis les contacts).
  Future<({List<String> all, List<String> exhibitors})> categories(
      int eventId) async {
    final page = await list(eventId);
    return (all: page.categories, exhibitors: page.exhibitorCategories);
  }

  Future<void> delete(int eventId, int invitationId) =>
      ApiClient.dio.delete('${_base(eventId)}/$invitationId');

  /// Contacts cochés : une seule requête, même rapport que l'import CSV.
  Future<InvitationReport> batch(
    int eventId,
    List<({String name, String phone})> contacts, {
    String? category,
  }) async {
    final response = await ApiClient.dio.post('${_base(eventId)}/batch', data: {
      'invitations': [
        for (final c in contacts) {'name': c.name, 'phone': c.phone},
      ],
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
    });
    return InvitationReport.fromJson(response.data as Map<String, dynamic>);
  }

  /// « Envoyer au suivant » : prochaine invitation pas encore envoyée.
  Future<({EventInvitation? next, int remaining})> next(int eventId) async {
    final response = await ApiClient.dio.get('${_base(eventId)}/next');
    final data = response.data['data'];
    return (
      next: data is Map
          ? EventInvitation.fromJson(data.cast<String, dynamic>())
          : null,
      remaining: (response.data['remaining'] as num?)?.toInt() ?? 0,
    );
  }

  /// À appeler APRÈS l'ouverture de WhatsApp ou le partage : suit le statut.
  Future<void> markSent(int eventId, int invitationId) =>
      ApiClient.dio.post('${_base(eventId)}/$invitationId/send');

  /// Invitation portrait 1080 × 1350 (PNG), pour le partage.
  Future<Uint8List> image(int eventId, int invitationId) async {
    final response = await ApiClient.dio.get<List<int>>(
      '${_base(eventId)}/$invitationId/image.png',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// Message lisible d'une erreur d'API (validation 422 comprise).
  static String errorMessage(Object error,
      {String fallback = 'Une erreur est survenue. Réessayez.'}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (error.response == null) {
        return 'Connexion impossible. Vérifiez votre réseau.';
      }
      if (error.response?.statusCode == 429) {
        return 'Trop de demandes en peu de temps. Patientez une minute.';
      }
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return '${first.first}';
        }
        if (data['message'] is String) return data['message'] as String;
      }
    }
    return fallback;
  }
}

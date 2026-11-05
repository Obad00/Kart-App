import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/company_event_summary.dart';
import '../models/event_participant_summary.dart';

/// Vue "communauté" d'une entreprise depuis l'app mobile — ses événements
/// (avec inscrits/présents), le détail des participants de chacun, et la
/// liste des employés rattachés. Réutilise tel quel les endpoints déjà
/// exposés au CRM (EventController, EmployeeManagementController) : aucun
/// endpoint mobile dédié n'a été nécessaire.
class CompanyCommunityService {
  Future<List<CompanyEventSummary>> fetchEvents() async {
    final response = await ApiClient.dio.get('/events');
    return (response.data['events'] as List)
        .map((e) => CompanyEventSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<
      ({
        List<EventParticipantSummary> participants,
        Map<String, dynamic> stats,
      })> fetchParticipants(int eventId) async {
    final response = await ApiClient.dio.get('/events/$eventId/participants');
    final participants = (response.data['participants'] as List)
        .map(
            (e) => EventParticipantSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    final stats =
        (response.data['stats'] as Map?)?.cast<String, dynamic>() ?? {};

    return (participants: participants, stats: stats);
  }

  /// Correction manuelle présent/absent — refusée par le backend tant que
  /// l'événement n'est pas terminé (cf. EventController::
  /// updateParticipantPresence()).
  Future<bool> setParticipantPresence(
    int eventId,
    int participantId,
    bool present,
  ) async {
    final response = await ApiClient.dio.patch(
      '/events/$eventId/participants/$participantId/presence',
      data: {'present': present},
    );
    final participant = response.data['participant'] as Map<String, dynamic>?;
    return participant?['isPresent'] as bool? ?? present;
  }

  /// Retire la participation de l'événement sans supprimer le compte KART.
  Future<void> removeParticipant(int eventId, int participantId) async {
    await ApiClient.dio.delete('/events/$eventId/participants/$participantId');
  }

  /// Badge d'un participant : « png » 300 dpi ou « pdf » au format exact
  /// du badge (cf. EventController::participantBadge()).
  Future<Uint8List> fetchParticipantBadge(int eventId, int participantId, String format) async {
    final response = await ApiClient.dio.get<List<int>>(
      '/events/$eventId/participants/$participantId/badge.$format',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  /// "Toute personne rattachée à cette entreprise" — 403 silencieux si le
  /// compte n'est pas owner/admin ou si l'entreprise n'est pas sur le plan
  /// enterprise (même comportement que CompanyProvider.loadMembers(), déjà
  /// non bloquant sur ce même 403).
  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final response = await ApiClient.dio.get(ApiEndpoints.companyEmployees);
    final data = response.data['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}

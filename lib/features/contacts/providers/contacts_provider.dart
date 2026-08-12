// ───────────────── ContactsProvider ─────────────────
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/highlight_group.dart';

class ContactsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<HighlightGroup> groups = [];
  String _query = '';

  /// 🔍 Retourne les groupes filtrés selon _query
  List<HighlightGroup> get filteredGroups {
    if (_query.isEmpty) return groups;

    final queryLower = _normalize(_query);

    final filtered = groups
        .map((group) {
          final filteredContacts = group.contacts.where((contact) {
            final name = _normalize(contact.fullname);
            final company = _normalize(contact.company ?? '');
            final email = _normalize(contact.email ?? '');
            final phone = contact.phone ?? '';

            return name.contains(queryLower) ||
                company.contains(queryLower) ||
                email.contains(queryLower) ||
                phone.contains(queryLower);
          }).toList();

          if (filteredContacts.isEmpty) return null;

          return HighlightGroup(
              highlight: group.highlight, contacts: filteredContacts);
        })
        .whereType<HighlightGroup>()
        .toList();

    if (kDebugMode) {
      debugPrint('🔍 Query: $_query');
      debugPrint(
          '🔍 Original groups: ${groups.map((g) => g.contacts.length).toList()}');
      debugPrint(
          '🔍 Filtered groups: ${filtered.map((g) => g.contacts.length).toList()}');
    }

    return filtered;
  }

  /// Met à jour la recherche
  void filterContacts(String value) {
    _query = value.trim();
    notifyListeners();
  }

  /// Chargement des contacts
  Future<void> fetchGroupedContacts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res = await ApiClient.dio.get('/contacts/grouped-by-highlight');
      final data = res.data;
      if (data is List) {
        groups = data
            .map((e) => HighlightGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        groups = [];
        debugPrint(
            '⚠️ Unexpected response format for contacts: ${data.runtimeType}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching contacts: $e');
      error = 'Impossible de charger les contacts';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Envoi d'un message via l'API
  Future<void> sendMessage({
    required List<int> contactIds,
    required String content,
    required String type, // "single" ou "group"
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/messages/send',
        data: {
          'contact_ids': contactIds,
          'content': content,
          'type': type,
        },
      );

      if (response.statusCode != 201) {
        throw Exception("Erreur lors de l'envoi du message");
      }

      if (kDebugMode) {
        debugPrint('📩 Message envoyé avec succès: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Erreur sendMessage: $e');
      rethrow;
    }
  }

  /// Partager/Relancer un contact via l'API
  Future<void> shareContact({
    required String slug,
    String? message,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '📤 Tentative de partage du contact: /cards/$slug/share-contact');
        debugPrint('📤 Message: ${message ?? "null"}');
      }

      final response = await ApiClient.dio.post(
        '/cards/$slug/share-contact',
        data: {
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      if (kDebugMode) {
        debugPrint('✅ Contact partagé avec succès: ${response.data}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur shareContact: $e');
        if (e is DioException) {
          debugPrint('❌ Status: ${e.response?.statusCode}');
          debugPrint('❌ Response: ${e.response?.data}');
          debugPrint('❌ URL: ${e.requestOptions.uri}');
        }
      }
      rethrow;
    }
  }

  /// Supprime un contact via l'API et le retire localement des groupes.
  Future<void> deleteContact(int contactId) async {
    await ApiClient.dio.delete('/contacts/$contactId');

    groups = groups
        .map((group) => HighlightGroup(
              highlight: group.highlight,
              contacts: group.contacts.where((c) => c.id != contactId).toList(),
            ))
        .where((group) => group.contacts.isNotEmpty)
        .toList();

    notifyListeners();
  }

  /// Déplace un contact vers un highlight (ou le retire du highlight
  /// courant si [highlightId] est null), puis recharge les groupes depuis
  /// le serveur (plus simple/fiable que de reconstruire les groupes en local).
  Future<void> moveContactToHighlight(int contactId, int? highlightId) async {
    await ApiClient.dio.patch(
      '/contacts/$contactId/highlight',
      data: {'highlight_id': highlightId},
    );
    await fetchGroupedContacts();
  }

  void clear() {
    groups = [];
    _query = '';
    error = null;
    isLoading = false;
    notifyListeners();
  }

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[îïíì]'), 'i')
        .replaceAll(RegExp(r'[ôöòó]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool get noMatch => _query.isNotEmpty && filteredGroups.isEmpty;
}

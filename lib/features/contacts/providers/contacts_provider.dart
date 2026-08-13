// ───────────────── ContactsProvider ─────────────────
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/highlight_group.dart';
import '../models/contact_model.dart';

class ContactsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<HighlightGroup> groups = [];
  String _query = '';

  /// Tous les contacts, tous groupes confondus (pratique pour les vues
  /// "Tous"/"Favoris"/"Récents" qui affichent une liste plate) — chaque
  /// contact est enrichi du nom de son highlight (absent du JSON brut par
  /// contact, seul highlight_id y figure) pour l'afficher en badge sur sa
  /// ligne.
  List<ContactModel> get allContacts => groups
      .expand((g) => g.contacts.map((c) => c.copyWith(
            highlightName: g.highlight.id != 0 ? g.highlight.name : null,
          )))
      .toList();

  /// Contacts marqués favoris — alimente la rangée d'accès rapide en haut
  /// de la liste (équivalent "à la une").
  List<ContactModel> get favoriteContacts =>
      allContacts.where((c) => c.isFavorite).toList();

  /// Un contact correspond-il à la recherche en cours (nom, entreprise,
  /// email, téléphone) ? Exposé publiquement pour que les vues "Tous" et
  /// "Récents" (listes plates) filtrent avec exactement la même logique
  /// que [filteredGroups], plutôt que de dupliquer une recherche
  /// approximative (nom seul) côté widget.
  bool matchesQuery(ContactModel contact, [String? query]) {
    final q = _normalize(query ?? _query);
    if (q.isEmpty) return true;

    final name = _normalize(contact.fullname);
    final company = _normalize(contact.company ?? '');
    final email = _normalize(contact.email ?? '');
    final phone = contact.phone ?? '';

    return name.contains(q) ||
        company.contains(q) ||
        email.contains(q) ||
        phone.contains(q);
  }

  /// 🔍 Retourne les groupes filtrés selon _query
  List<HighlightGroup> get filteredGroups {
    if (_query.isEmpty) return groups;

    final filtered = groups
        .map((group) {
          final filteredContacts =
              group.contacts.where((c) => matchesQuery(c)).toList();

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

  /// Bascule le statut favori d'un contact (mise à jour optimiste, puis
  /// confirmation serveur — annule le changement local en cas d'échec).
  Future<void> toggleFavorite(int contactId) async {
    HighlightGroup? groupOf(int id) =>
        groups.where((g) => g.contacts.any((c) => c.id == id)).firstOrNull;

    final group = groupOf(contactId);
    final contact = group?.contacts.firstWhere((c) => c.id == contactId);
    if (group == null || contact == null) return;

    _replaceContact(contactId, contact.copyWith(isFavorite: !contact.isFavorite));

    try {
      await ApiClient.dio.patch('/contacts/$contactId/favorite');
    } catch (e) {
      debugPrint('❌ Erreur toggleFavorite: $e');
      // Rollback si l'appel serveur échoue.
      _replaceContact(contactId, contact);
      rethrow;
    }
  }

  void _replaceContact(int contactId, ContactModel updated) {
    groups = groups
        .map((group) => HighlightGroup(
              highlight: group.highlight,
              contacts: group.contacts
                  .map((c) => c.id == contactId ? updated : c)
                  .toList(),
            ))
        .toList();
    notifyListeners();
  }

  /// Création manuelle d'un contact (nom, email, téléphone) — le contact
  /// reçoit un mail KART l'invitant à créer sa carte si un email est fourni
  /// (géré côté serveur). Recharge la liste depuis le serveur ensuite.
  Future<void> createManualContact({
    required String fullname,
    String? email,
    String? phone,
    String? company,
  }) async {
    await ApiClient.dio.post('/contacts', data: {
      'fullname': fullname,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (company != null && company.isNotEmpty) 'company': company,
    });
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

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../models/highlight_group.dart';

class ContactsProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  List<HighlightGroup> groups = [];

  String _query = '';

  /// 🔍 iOS-style filtering
  List<HighlightGroup> get filteredGroups {
    if (_query.isEmpty) return groups;

    return groups
        .map((group) {
          final filteredContacts = group.contacts.where((contact) {
            return contact.fullname
                .toLowerCase()
                .contains(_query.toLowerCase());
          }).toList();

          return HighlightGroup(
            highlight: group.highlight,
            contacts: filteredContacts,
          );
        })
        .where((group) => group.contacts.isNotEmpty)
        .toList();
  }

  void filterContacts(String value) {
    _query = value.trim();
    notifyListeners();
  }

  Future<void> fetchGroupedContacts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final res =
          await ApiClient.dio.get('/contacts/grouped-by-highlight');

      groups = (res.data as List)
          .map((e) => HighlightGroup.fromJson(e))
          .toList();
    } catch (e) {
      error = 'Impossible de charger les contacts';
    }

    isLoading = false;
    notifyListeners();
  }
}

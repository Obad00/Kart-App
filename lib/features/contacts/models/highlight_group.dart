import 'contact_model.dart';
import 'highlight_model.dart';

class HighlightGroup {
  final HighlightModel highlight;
  final List<ContactModel> contacts;

  HighlightGroup({
    required this.highlight,
    required this.contacts,
  });

  factory HighlightGroup.fromJson(Map<String, dynamic> json) {
    final highlightData = json['highlight'];
    final contactsData = json['contacts'];

    return HighlightGroup(
      highlight: highlightData != null
          ? HighlightModel.fromJson(highlightData as Map<String, dynamic>)
          : HighlightModel(id: 0, name: 'Unknown', isActive: false),
      contacts: contactsData is List
          ? contactsData.map((e) => ContactModel.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

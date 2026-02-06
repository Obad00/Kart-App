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
    return HighlightGroup(
      highlight: HighlightModel.fromJson(json['highlight']),
      contacts: (json['contacts'] as List)
          .map((e) => ContactModel.fromJson(e))
          .toList(),
    );
  }
}

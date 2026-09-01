class HighlightModel {
  final int id;
  final String name;
  final bool isActive;
  // Présents seulement quand ce highlight vient d'une inscription à un
  // événement KART (formulaire public /events/{slug}/register) — voir
  // EventRegistrationService::ensureEventHighlight() côté backend.
  final bool isCompanyEvent;
  final int? eventId;
  final DateTime? eventDate;
  final String? eventLocation;

  HighlightModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.isCompanyEvent = false,
    this.eventId,
    this.eventDate,
    this.eventLocation,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      isCompanyEvent: json['is_company_event'] == true || json['is_company_event'] == 1,
      eventId: json['event_id'] != null ? int.tryParse(json['event_id'].toString()) : null,
      eventDate: json['event_date'] != null ? DateTime.tryParse(json['event_date'].toString()) : null,
      eventLocation: json['event_location'],
    );
  }
}

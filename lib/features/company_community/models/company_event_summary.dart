/// Un des événements créés par l'entreprise du compte connecté — cf.
/// EventController::index() (CRM entreprise, réutilisé tel quel ici,
/// aucun endpoint mobile dédié n'a été nécessaire).
class CompanyEventSummary {
  final int id;
  final String name;
  final String? location;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isActive;
  final int participantsCount;

  const CompanyEventSummary({
    required this.id,
    required this.name,
    this.location,
    this.startsAt,
    this.endsAt,
    required this.isActive,
    required this.participantsCount,
  });

  factory CompanyEventSummary.fromJson(Map<String, dynamic> json) {
    return CompanyEventSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      location: json['location'] as String?,
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'] as String)
          : null,
      isActive: json['is_active'] == true,
      participantsCount: json['participants_count'] as int? ?? 0,
    );
  }

  /// Un événement passé n'a plus vocation à recevoir de check-in — même
  /// logique que Event::isCurrentlyActive() côté backend, reproduite ici
  /// pour l'affichage (badge "Terminé") sans aller-retour réseau.
  bool get hasEnded => endsAt != null && endsAt!.isBefore(DateTime.now());
}

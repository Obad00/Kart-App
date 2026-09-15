/// Une ligne de la table "Participant / Statut / Profil KART" demandée
/// côté produit — cf. EventController::participants() (user.digitalCard
/// déjà chargé côté backend pour ce détail).
class EventParticipantSummary {
  final int id;
  final String displayName;
  final String? email;
  final String? jobTitle;
  final String? company;
  final String? avatar;
  // Compte KART créé — false tant qu'un visiteur walk-in n'a pas encore
  // créé le sien (cf. EventCheckinService::checkInWalkIn côté backend).
  final bool hasAccount;
  final bool isPresent;
  final bool isWalkIn;
  final DateTime? registeredAt;

  const EventParticipantSummary({
    required this.id,
    required this.displayName,
    this.email,
    this.jobTitle,
    this.company,
    this.avatar,
    required this.hasAccount,
    required this.isPresent,
    required this.isWalkIn,
    this.registeredAt,
  });

  factory EventParticipantSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final digitalCard = user?['digital_card'] as Map<String, dynamic>?;
    final guestLabel = json['guest_label'] as String?;

    final name = user != null
        ? '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim()
        : (guestLabel ?? 'Visiteur');

    return EventParticipantSummary(
      id: json['id'] as int,
      displayName: name.isEmpty ? 'Visiteur' : name,
      email: user?['email'] as String?,
      jobTitle: digitalCard?['job_title'] as String?,
      company: digitalCard?['company'] as String?,
      avatar: user?['avatar'] as String?,
      hasAccount: user != null,
      isPresent: json['checked_in_at'] != null,
      isWalkIn: json['is_walk_in'] == true,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'] as String)
          : null,
    );
  }
}

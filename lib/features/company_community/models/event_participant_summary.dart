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
  // Coordonnées : remonté côté produit — l'admin doit voir "les
  // informations de celui qui s'est inscrit", pas juste son nom.
  final String? phone;
  // Identifiant du compte KART derrière ce participant (null pour un
  // walk-in pas encore rattaché) + état de la relation avec le compte qui
  // consulte, pour proposer "Se connecter" comme ailleurs dans Explorer
  // (cf. EventController::participants(), même calcul que attendees()).
  final int? userId;
  final String connectionStatus;
  final int? connectionRequestId;
  final String? cardSlug;

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
    this.phone,
    this.userId,
    this.connectionStatus = 'none',
    this.connectionRequestId,
    this.cardSlug,
  });

  static const unnamed = 'Participant sans nom';

  factory EventParticipantSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final digitalCard = user?['digital_card'] as Map<String, dynamic>?;
    final guestLabel = json['guest_label'] as String?;

    final phone = (json['contact_phone'] as String?) ??
        (digitalCard?['phone'] as String?) ??
        (user?['phone'] as String?);
    // Nom calculé par l'API (nom, sinon téléphone, sinon « Participant sans
    // nom ») ; même repli ici pour une réponse plus ancienne.
    final name = (json['display_name'] as String?)?.trim().isNotEmpty == true
        ? (json['display_name'] as String).trim()
        : (user != null
                ? '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim()
                : (guestLabel ?? '').trim())
            .ifEmpty(phone ?? unnamed);
    final email = (json['contact_email'] as String?) ?? (user?['email'] as String?);

    return EventParticipantSummary(
      id: json['id'] as int,
      displayName: name,
      // Jamais l'adresse technique d'un compte créé avec un numéro seul.
      email: email != null && !email.toLowerCase().endsWith('@kart-evenement.local') ? email : null,
      jobTitle: digitalCard?['job_title'] as String?,
      company: digitalCard?['company'] as String?,
      avatar: user?['avatar'] as String?,
      hasAccount: user != null,
      isPresent: json['checked_in_at'] != null,
      isWalkIn: json['is_walk_in'] == true,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'] as String)
          : null,
      // Le téléphone de la carte d'abord (celui que la personne a choisi
      // d'exposer), sinon celui du compte.
      phone: phone,
      userId: user?['id'] as int?,
      connectionStatus: json['connection_status'] as String? ?? 'none',
      connectionRequestId: json['connection_request_id'] as int?,
      cardSlug: digitalCard?['slug'] as String?,
    );
  }

  EventParticipantSummary copyWith({bool? isPresent}) {
    return EventParticipantSummary(
      id: id,
      displayName: displayName,
      email: email,
      jobTitle: jobTitle,
      company: company,
      avatar: avatar,
      hasAccount: hasAccount,
      isPresent: isPresent ?? this.isPresent,
      isWalkIn: isWalkIn,
      registeredAt: registeredAt,
      phone: phone,
      userId: userId,
      connectionStatus: connectionStatus,
      connectionRequestId: connectionRequestId,
      cardSlug: cardSlug,
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

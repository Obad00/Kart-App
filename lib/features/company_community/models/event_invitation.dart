/// Invitation WhatsApp d'un événement (cf. EventInvitationController côté
/// backend). `whatsappUrl` et `message` viennent toujours du backend : l'app
/// ne recalcule jamais le lien wa.me, ni l'encodage du message.
class EventInvitation {
  final int id;
  final String type;
  final String name;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? category;
  final String? civility;
  final String? guestTitle;
  final String? honorMessage;
  final String? shortUrl;
  final bool createdNow;

  /// Numéro de stand d'un exposant (imprimé en grand sur son badge).
  final String? standNumber;
  final InvitationStatus status;
  final DateTime? sentAt;
  final DateTime? openedAt;
  final bool needsReminder;
  final String? whatsappUrl;
  final String? message;

  const EventInvitation({
    required this.id,
    this.type = 'standard',
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.category,
    this.civility,
    this.guestTitle,
    this.honorMessage,
    this.shortUrl,
    this.createdNow = true,
    this.standNumber,
    required this.status,
    this.sentAt,
    this.openedAt,
    this.needsReminder = false,
    this.whatsappUrl,
    this.message,
  });

  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] is String ? DateTime.tryParse(json[key] as String) : null;

    return EventInvitation(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'standard',
      name: json['name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      category: json['category'] as String?,
      civility: json['civility'] as String?,
      guestTitle: json['guest_title'] as String?,
      honorMessage: json['honor_message'] as String?,
      shortUrl: json['short_url'] as String?,
      createdNow: json['created'] != false,
      standNumber: json['stand_number'] as String?,
      status: InvitationStatus.fromApi(json['status'] as String?),
      sentAt: date('sent_at'),
      openedAt: date('opened_at'),
      needsReminder: json['needs_reminder'] == true,
      whatsappUrl: json['whatsapp_url'] as String?,
      message: json['message'] as String?,
    );
  }

  /// Même règle que le filtre du serveur (EventInvitationController) :
  /// « Envoyée » = déjà envoyée (sent_at), « Ouverte » = déjà ouverte,
  /// sinon le statut ; recherche dans le nom, le numéro et l'email. Sert au
  /// filtrage immédiat, avant la réponse du serveur.
  bool matches(
      {InvitationStatus? status, String? category, String query = ''}) {
    final statusOk = switch (status) {
      null => true,
      InvitationStatus.sent =>
        sentAt != null || this.status == InvitationStatus.sent,
      InvitationStatus.opened =>
        openedAt != null || this.status == InvitationStatus.opened,
      _ => this.status == status,
    };
    if (!statusOk) return false;
    if (category != null && category.isNotEmpty && this.category != category) {
      return false;
    }
    final q = query.trim().toLowerCase();
    return q.isEmpty ||
        name.toLowerCase().contains(q) ||
        phone.toLowerCase().contains(q) ||
        (email ?? '').toLowerCase().contains(q);
  }

  String get initials {
    final letters = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }
}

enum InvitationStatus {
  pending('pending', 'À envoyer'),
  sent('sent', 'Envoyée'),
  opened('opened', 'Ouverte'),
  confirmed('confirmed', 'Confirmée'),
  declined('declined', 'Déclinée');

  final String api;
  final String label;
  const InvitationStatus(this.api, this.label);

  static InvitationStatus fromApi(String? value) =>
      InvitationStatus.values.firstWhere((s) => s.api == value,
          orElse: () => InvitationStatus.pending);
}

/// Compteurs de l'onglet (cf. `counts` de GET /events/{id}/invitations).
class InvitationCounts {
  final int invited;
  final int pending;
  final int sent;
  final int opened;
  final int confirmed;
  final int declined;

  const InvitationCounts({
    this.invited = 0,
    this.pending = 0,
    this.sent = 0,
    this.opened = 0,
    this.confirmed = 0,
    this.declined = 0,
  });

  factory InvitationCounts.fromJson(Map<String, dynamic>? json) {
    int read(String key) => (json?[key] as num?)?.toInt() ?? 0;
    return InvitationCounts(
      invited: read('invited'),
      pending: read('pending'),
      sent: read('sent'),
      opened: read('opened'),
      confirmed: read('confirmed'),
      declined: read('declined'),
    );
  }
}

/// Une page de la liste, avec les compteurs et les catégories existantes.
class InvitationPage {
  final List<EventInvitation> items;
  final InvitationCounts counts;
  final List<String> categories;
  final int currentPage;
  final int lastPage;

  /// Événement terminé : liste en lecture seule (plus d'ajout ni d'envoi).
  final bool eventEnded;

  /// Catégories d'exposants : le formulaire propose alors le numéro de stand.
  final List<String> exhibitorCategories;

  const InvitationPage({
    required this.items,
    required this.counts,
    required this.categories,
    required this.currentPage,
    required this.lastPage,
    this.eventEnded = false,
    this.exhibitorCategories = const [],
  });

  factory InvitationPage.fromJson(Map<String, dynamic> json) {
    final pagination = (json['pagination'] as Map?)?.cast<String, dynamic>();
    return InvitationPage(
      items: (json['data'] as List? ?? [])
          .map((e) => EventInvitation.fromJson(e as Map<String, dynamic>))
          .toList(),
      counts: InvitationCounts.fromJson(
          (json['counts'] as Map?)?.cast<String, dynamic>()),
      categories: (json['categories'] as List? ?? []).map((c) => '$c').toList(),
      currentPage: (pagination?['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (pagination?['last_page'] as num?)?.toInt() ?? 1,
      eventEnded: json['event_ended'] == true,
      exhibitorCategories: (json['exhibitor_categories'] as List? ?? [])
          .map((c) => '$c')
          .toList(),
    );
  }
}

/// Rapport d'ajout (import CSV ou ajout en lot depuis les contacts).
class InvitationReport {
  final int created;
  final int duplicates;
  final List<({int line, String name, String reason})> invalid;

  /// Numéro envoyé pour chaque ligne (ajout en lot : position dans la
  /// liste), pour l'afficher à côté d'un refus. Vide pour l'import CSV.
  final Map<int, String> phonesByLine;

  const InvitationReport({
    required this.created,
    required this.duplicates,
    required this.invalid,
    this.phonesByLine = const {},
  });

  InvitationReport withPhones(Map<int, String> phones) => InvitationReport(
        created: created,
        duplicates: duplicates,
        invalid: invalid,
        phonesByLine: phones,
      );

  factory InvitationReport.fromJson(Map<String, dynamic> json) {
    return InvitationReport(
      created: (json['created'] as num?)?.toInt() ?? 0,
      duplicates: (json['duplicates'] as num?)?.toInt() ?? 0,
      invalid: (json['invalid'] as List? ?? []).map((e) {
        final row = (e as Map).cast<String, dynamic>();
        return (
          line: (row['line'] as num?)?.toInt() ?? 0,
          name: row['name'] as String? ?? '',
          reason: row['reason'] as String? ?? '',
        );
      }).toList(),
    );
  }
}

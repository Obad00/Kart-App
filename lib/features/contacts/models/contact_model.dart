class ContactModel {
  final int id;
  final String fullname;
  final String? email;
  final String? phone;
  final String? company;
  final String? job;
  final String? cardSlug;
  final String? linkedin;
  final String? twitter;
  final String? facebook;
  final String? instagram;
  final String? website;
  final int? highlightId;
  final String? avatar;
  final bool isFavorite;
  final DateTime? capturedAt;
  // Renseigné côté client lors de l'aplatissement des groupes (l'API ne
  // renvoie que highlight_id par contact, pas le nom) — voir
  // ContactsProvider.allContacts.
  final String? highlightName;

  ContactModel({
    required this.id,
    required this.fullname,
    this.email,
    this.phone,
    this.company,
    this.job,
    this.cardSlug,
    this.linkedin,
    this.twitter,
    this.facebook,
    this.instagram,
    this.website,
    this.highlightId,
    this.avatar,
    this.isFavorite = false,
    this.capturedAt,
    this.highlightName,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullname: json['fullname'] ?? json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      job: json['job'],
      cardSlug: json['card_slug'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      website: json['website'],
      highlightId: json['highlight_id'] != null
          ? int.tryParse(json['highlight_id'].toString())
          : null,
      avatar: json['avatar'],
      isFavorite: json['is_favorite'] == true,
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at'].toString())
          : null,
    );
  }

  ContactModel copyWith({bool? isFavorite, String? highlightName}) {
    return ContactModel(
      id: id,
      fullname: fullname,
      email: email,
      phone: phone,
      company: company,
      job: job,
      cardSlug: cardSlug,
      linkedin: linkedin,
      twitter: twitter,
      facebook: facebook,
      instagram: instagram,
      website: website,
      highlightId: highlightId,
      avatar: avatar,
      isFavorite: isFavorite ?? this.isFavorite,
      capturedAt: capturedAt,
      highlightName: highlightName ?? this.highlightName,
    );
  }
}

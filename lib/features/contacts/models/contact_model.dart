class ContactModel {
  final int id;
  final String fullname;
  final String? email;
  final String? phone;
  final String? company;
  final String? cardSlug;

  ContactModel({
    required this.id,
    required this.fullname,
    this.email,
    this.phone,
    this.company,
    this.cardSlug,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      fullname: json['fullname'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      cardSlug: json['card_slug'],
    );
  }
}

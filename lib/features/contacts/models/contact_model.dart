class ContactModel {
  final int id;
  final String fullname;
  final String? email;
  final String? phone;
  final String? company;
  final String? cardSlug;
  final String? linkedin;

  ContactModel({
    required this.id,
    required this.fullname,
    this.email,
    this.phone,
    this.company,
    this.cardSlug,
    this.linkedin,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullname: json['fullname'] ?? json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      cardSlug: json['card_slug'],
      linkedin: json['linkedin'],
    );
  }
}

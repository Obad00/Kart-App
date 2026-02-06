class ContactModel {
  final int id;
  final String fullname;
  final String? email;
  final String? phone;
  final String? company;

  ContactModel({
    required this.id,
    required this.fullname,
    this.email,
    this.phone,
    this.company,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'],
      fullname: json['fullname'] ?? '',
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
    );
  }
}

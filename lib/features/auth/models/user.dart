import '../../onboarding/models/company.dart';

class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String plan;
  final int? companyId;
  final Company? company;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.plan,
    this.companyId,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      plan: json['plan'] ?? 'free',
      companyId: json['company_id'],
      company: json['company'] != null
          ? Company.fromJson(json['company'])
          : null,
    );
  }

  bool get isPro => plan != 'free';
  // Vérifie si l'utilisateur a une entreprise (soit via company_id, soit via l'objet company)
  bool get hasCompany => companyId != null || company != null;
}

import '../../onboarding/models/company.dart';

class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String plan;
  final Company? company; // 👈 AJOUT IMPORTANT

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.plan,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  return User(
    id: json['id'],
    firstname: json['firstname'],
    lastname: json['lastname'],
    email: json['email'],
    plan: json['plan'] ?? 'free',
    company: json['company'] != null
        ? Company.fromJson(json['company'])
        : null,
  );
}


  bool get isPro => plan != 'free';
  bool get hasCompany => company != null;
}

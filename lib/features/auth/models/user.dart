class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String plan;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.plan,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email'],
      plan: json['plan'] ?? 'free',
    );
  }

  bool get isPro => plan == 'pro';
}

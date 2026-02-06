class Company {
  final int id;
  final String name;
  final String? logo;
  final String? primaryColor;
  final String licenseCode;
  final int maxUsers;
  final String plan;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    this.logo,
    this.primaryColor,
    required this.licenseCode,
    required this.maxUsers,
    required this.plan,
    required this.isActive,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
      primaryColor: json['primary_color'],
      licenseCode: json['license_code'],
      maxUsers: json['max_users'],
      plan: json['plan'],
      isActive: json['is_active'] == true,
    );
  }
}

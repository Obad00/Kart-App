class ScannedContact {
  String? firstName;
  String? lastName;
  String? jobTitle;
  String? company;
  String? email;
  String? phone;
  String? address;
  String? website;
  final String? rawText;

  ScannedContact({
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.company,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.rawText,
  });

  factory ScannedContact.fromJson(Map<String, dynamic> json, String? rawText) {
    return ScannedContact(
      firstName: json['first_name'],
      lastName: json['last_name'],
      jobTitle: json['job_title'],
      company: json['company'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      website: json['website'],
      rawText: rawText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstName,
      'lastname': lastName,
      'job_title': jobTitle,
      'company': company,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'source': 'card_scan',
    };
  }

  bool get hasMinimumData {
    return (firstName != null && firstName!.isNotEmpty) ||
        (lastName != null && lastName!.isNotEmpty) ||
        (email != null && email!.isNotEmpty) ||
        (phone != null && phone!.isNotEmpty);
  }

  String get displayName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isNotEmpty ? parts.join(' ') : 'Contact sans nom';
  }
}

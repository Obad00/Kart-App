import 'package:flutter/foundation.dart';
import '../../onboarding/models/company.dart';

class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? avatar;
  final String? phone;
  final String plan;
  final String accountType;
  final String? companyRole;
  final bool mustChangePassword;
  final int? companyId;
  final Company? company;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.avatar,
    this.phone,
    required this.plan,
    this.accountType = 'standard',
    this.companyRole,
    this.mustChangePassword = false,
    this.companyId,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    debugPrint('👤 Parsing User from JSON:');
    debugPrint('   - firstname: ${json['firstname']}');
    debugPrint('   - lastname: ${json['lastname']}');
    debugPrint('   - email: ${json['email']}');
    debugPrint('   - phone: ${json['phone']}');
    debugPrint('   - company (raw): ${json['company']}');

    Company? parsedCompany;

    try {
      if (json['company'] != null) {
        parsedCompany = Company.fromJson(json['company']);
        debugPrint('✅ Company parsed successfully: ${parsedCompany.name}');
      } else {
        debugPrint('⚠️ No company data in JSON');
      }
    } catch (e) {
      debugPrint('❌ Error parsing Company: $e');
    }

    // company_id n'est plus renvoyé à plat par le backend : il est nesté
    // dans l'objet company (voir AuthService::buildUserPayload).
    final rawCompanyId = json['company_id'] ?? json['company']?['id'];

    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // Handle both 'firstname'/'name' and nested 'user' object from backend
      firstname: json['firstname'] ?? json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'],
      plan: json['plan'] ?? 'free',
      accountType: json['account_type'] ?? 'standard',
      companyRole: json['company_role'],
      mustChangePassword: json['must_change_password'] == true,
      companyId:
          rawCompanyId != null ? int.tryParse(rawCompanyId.toString()) : null,
      company: parsedCompany,
    );
  }

  bool get isPro => plan != 'free';
  bool get hasCompany => companyId != null || company != null;
  bool get isCompanyOwnerOrAdmin =>
      companyRole == 'owner' || companyRole == 'admin';
  String get fullName => '$firstname $lastname';
}

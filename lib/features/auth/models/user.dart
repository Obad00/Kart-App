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
    this.companyId,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    debugPrint('👤 Parsing User from JSON:');
    debugPrint('   - email: ${json['email']}');
    debugPrint('   - company_id: ${json['company_id']}');
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

    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      // Handle both 'firstname'/'name' and nested 'user' object from backend
      firstname: json['firstname'] ?? json['name'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'],
      plan: json['plan'] ?? 'free',
      companyId: json['company_id'] != null ? int.tryParse(json['company_id'].toString()) : null,
      company: parsedCompany,
    );
  }

  bool get isPro => plan != 'free';
  bool get hasCompany => companyId != null || company != null;
  String get fullName => '$firstname $lastname';
}
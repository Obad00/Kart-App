// import 'package:flutter/foundation.dart';

class Company {
  final int id;
  final String name;
  final String? logo;
  final String? primaryColor;
  final String? secondaryColor;
  final String? backgroundImage;
  final String cardTheme;
  final String? fontFamily;
  final bool brandingEnabled;
  final String licenseCode;
  final int maxUsers;
  final int? subscriptionId;
  final bool isActive;

  Company({
    required this.id,
    required this.name,
    this.logo,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundImage,
    required this.cardTheme,
    this.fontFamily,
    required this.brandingEnabled,
    required this.licenseCode,
    required this.maxUsers,
    this.subscriptionId,
    required this.isActive,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    // Debug pour voir ce qui est reçu
    // debugPrint('🏢 Parsing Company from JSON:');
    // debugPrint('   - id: ${json['id']}');
    // debugPrint('   - name: ${json['name']}');
    // debugPrint('   - card_theme: ${json['card_theme']}');
    // debugPrint('   - license_code: ${json['license_code']}');
    
    return Company(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      backgroundImage: json['background_image'],
      cardTheme: json['card_theme'] ?? 'default',
      fontFamily: json['font_family'],
      brandingEnabled: json['branding_enabled'] == 1 || json['branding_enabled'] == true,
      licenseCode: json['license_code'] ?? '',
      maxUsers: int.tryParse(json['max_users']?.toString() ?? '1') ?? 1,
      subscriptionId: json['subscription_id'] != null ? int.tryParse(json['subscription_id'].toString()) : null,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'background_image': backgroundImage,
      'card_theme': cardTheme,
      'font_family': fontFamily,
      'branding_enabled': brandingEnabled,
      'license_code': licenseCode,
      'max_users': maxUsers,
      'subscription_id': subscriptionId,
      'is_active': isActive,
    };
  }
}
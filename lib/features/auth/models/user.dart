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
  // Utilisé par l'écran "Vérifiez votre email" post-inscription (cf.
  // EmailVerificationPage) — absent des anciennes réponses /me en cache,
  // d'où le défaut à true pour ne jamais bloquer un compte existant.
  final bool emailVerified;
  // Compte créé via l'inscription événement avec un code PIN à 4 chiffres
  // comme mot de passe (EventRegistrationService, côté backend) — pilote
  // le nudge non bloquant "Sécurisez votre compte" (cf. SecurePinBanner),
  // distinct de mustChangePassword qui bloque l'accès à l'app.
  final bool hasTemporaryPin;
  // Accès à "Ma communauté" délégué par l'admin à un collaborateur
  // (company_role = member) sans le promouvoir admin — cf.
  // User::canManageCompanyCommunity() côté backend. Un owner/admin y a
  // toujours accès, indépendamment de ce champ (cf. canAccessCommunity).
  final bool canManageCommunity;

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
    this.emailVerified = true,
    this.hasTemporaryPin = false,
    this.canManageCommunity = false,
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
      // Absent dans une réponse plus ancienne (avant ce champ) : on
      // considère alors l'email déjà vérifié plutôt que de bloquer un
      // compte existant à tort.
      emailVerified: json['email_verified'] ?? true,
      hasTemporaryPin: json['has_temporary_pin'] == true,
      canManageCommunity: json['can_manage_community'] == true,
    );
  }

  bool get isPro => plan != 'free';
  bool get hasCompany => companyId != null || company != null;
  bool get isCompanyOwnerOrAdmin =>
      companyRole == 'owner' || companyRole == 'admin';
  /// Qui peut ouvrir "Ma communauté" (événements/participants de
  /// l'entreprise) : owner/admin toujours, plus tout collaborateur à qui
  /// l'admin a explicitement délégué cet accès depuis le CRM — remonté
  /// côté produit : les collaborateurs ne la voyaient dans aucun cas.
  bool get canAccessCompanyCommunity =>
      isCompanyOwnerOrAdmin || canManageCommunity;
  String get fullName => '$firstname $lastname';
}

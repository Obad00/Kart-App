import 'package:flutter/foundation.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/services/card_service.dart';

/// Modele representant un lead (personne ayant vu/scanne la carte)
class Lead {
  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String source;
  final DateTime viewedAt;
  final String? device;
  final String? location;
  final String? ipAddress;
  final String? userAgent;

  // Informations de l'utilisateur Kart (si c'est un utilisateur enregistré)
  final int? userId;
  final String? userFirstname;
  final String? userLastname;
  final String? userAvatar;
  final String? userJobTitle;
  final String? userCompany;

  Lead({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.source,
    required this.viewedAt,
    this.device,
    this.location,
    this.ipAddress,
    this.userAgent,
    // Champs utilisateur
    this.userId,
    this.userFirstname,
    this.userLastname,
    this.userAvatar,
    this.userJobTitle,
    this.userCompany,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as int,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      source: json['source'] as String? ?? 'unknown',
      viewedAt: DateTime.parse(json['viewed_at'] as String),
      device: json['device'] as String?,
      location: json['location'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      // Champs utilisateur depuis le backend
      userId: json['user_id'] as int?,
      userFirstname: json['user_firstname'] as String?,
      userLastname: json['user_lastname'] as String?,
      userAvatar: json['user_avatar'] as String?,
      userJobTitle: json['user_job_title'] as String?,
      userCompany: json['user_company'] as String?,
    );
  }

  /// Retourne le nom affichable du lead
  String get displayName {
    // PRIORITÉ 1: Si c'est un utilisateur Kart enregistré, afficher son nom complet
    if (userId != null && userFirstname != null && userLastname != null) {
      return '$userFirstname $userLastname';
    }

    // PRIORITÉ 2: Nom saisi manuellement via le formulaire
    if (name != null && name!.isNotEmpty) return name!;

    // PRIORITÉ 3: Email ou téléphone du formulaire
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;

    // PRIORITÉ 4: Utiliser les informations disponibles pour un affichage plus informatif
    if (location != null && location!.isNotEmpty) {
      return 'Visiteur de $location';
    }

    if (device != null && device!.isNotEmpty) {
      // Extraire le type de device si possible (ex: "iPhone", "Samsung Galaxy")
      final deviceName = _extractDeviceName(device!);
      return 'Visiteur sur $deviceName';
    }

    if (ipAddress != null && ipAddress!.isNotEmpty) {
      return 'Visiteur (${ipAddress!.substring(0, ipAddress!.length > 12 ? 12 : ipAddress!.length)}...)';
    }

    return 'Visiteur anonyme';
  }

  /// Extrait un nom de device lisible
  String _extractDeviceName(String deviceInfo) {
    // Essayer d'extraire un nom de device lisible
    final lowerDevice = deviceInfo.toLowerCase();

    if (lowerDevice.contains('iphone')) return 'iPhone';
    if (lowerDevice.contains('ipad')) return 'iPad';
    if (lowerDevice.contains('android')) return 'Android';
    if (lowerDevice.contains('samsung')) return 'Samsung';
    if (lowerDevice.contains('huawei')) return 'Huawei';
    if (lowerDevice.contains('xiaomi')) return 'Xiaomi';
    if (lowerDevice.contains('windows')) return 'Windows';
    if (lowerDevice.contains('mac')) return 'Mac';
    if (lowerDevice.contains('linux')) return 'Linux';

    // Si on ne trouve rien de spécifique, retourner les premiers mots
    final words = deviceInfo.split(' ');
    if (words.isNotEmpty) {
      return words.first.length > 15
          ? '${words.first.substring(0, 15)}...'
          : words.first;
    }

    return 'appareil mobile';
  }

  /// Retourne true si le lead a des coordonnees ou est un utilisateur Kart
  bool get hasContactInfo =>
      userId != null || // C'est un utilisateur Kart enregistré
      (name != null && name!.isNotEmpty) ||
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);

  /// Retourne true si c'est un utilisateur Kart enregistré
  bool get isKartUser => userId != null;

  /// Retourne le nom complet de l'utilisateur Kart
  String get kartUserFullName {
    if (userFirstname != null && userLastname != null) {
      return '$userFirstname $userLastname';
    }
    return displayName;
  }

  /// Retourne les initiales de l'utilisateur Kart
  String get kartUserInitials {
    if (userFirstname != null && userLastname != null) {
      return '${userFirstname![0]}${userLastname![0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  /// Retourne l'icone correspondant a la source
  String get sourceLabel {
    switch (source) {
      case 'qr_scan':
        return 'Scan QR';
      case 'link_share':
        return 'Lien partage';
      case 'contact_form':
        return 'Formulaire';
      default:
        return 'Autre';
    }
  }
}

/// Provider pour gerer les leads
class LeadsProvider extends ChangeNotifier {
  List<Lead> _leads = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  List<Lead> get leads => _leads;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Charge les leads depuis l'API
  Future<void> loadLeads() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await CardService.getLeads();

      final leadsList = response['leads'] as List<dynamic>? ?? [];
      _leads = leadsList
          .map((json) => Lead.fromJson(json as Map<String, dynamic>))
          .toList();

      // Trier par date (plus recent en premier)
      _leads.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));

      _total = response['total'] as int? ?? _leads.length;
    } catch (e) {
      _error = getErrorMessage(e,
          fallback: 'Impossible de charger les contacts intéressés. Réessayez.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraichit les leads
  Future<void> refresh() => loadLeads();

  /// Retourne les leads avec coordonnees uniquement
  List<Lead> get leadsWithContact =>
      _leads.where((lead) => lead.hasContactInfo).toList();

  /// Retourne le nombre de leads avec coordonnees
  int get contactCount => leadsWithContact.length;
}

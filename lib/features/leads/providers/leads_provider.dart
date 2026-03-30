import 'package:flutter/foundation.dart';
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
    );
  }

  /// Retourne le nom affichable du lead
  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (email != null && email!.isNotEmpty) return email!;
    if (phone != null && phone!.isNotEmpty) return phone!;
    return 'Visiteur #$id';
  }

  /// Retourne true si le lead a des coordonnees
  bool get hasContactInfo =>
      (name != null && name!.isNotEmpty) ||
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);

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
      _error = e.toString();
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

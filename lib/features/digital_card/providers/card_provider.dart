import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../shared/services/card_service.dart';

import 'package:dio/dio.dart';
import '../exceptions/theme_forbidden_exception.dart';

enum CardStatus {
  idle,
  loading,
  hasCard,
  noCard,
  error,
}

class CardProvider extends ChangeNotifier {
  // --- STATUS ---
  CardStatus _status = CardStatus.idle;
  CardStatus get status => _status;

  // --- DATA ---
  String? _qrSvg;
  String? _error;

  String? jobTitle;
  String? company;
  String? phone;
  String? email;
  String? linkedin;
  String? _theme;
  String? get theme => _theme;

  String? website;
  String? github;
  String? instagram;
  String? facebook;

  List<dynamic> experiences = [];
  List<dynamic> educations = [];

  String? plan;

  int? scanCount;
  int? shareCount;

  // --- SLUG & SHARE URL ---
  String? _slug;
  String? _shareUrl;
  String? get slug => _slug;
  String? get shareUrl => _shareUrl;

  // --- COMPANY INFO ---
  String? _companyLogo;
  String? _companyPrimaryColor;
  String? get companyLogo => _companyLogo;
  String? get companyPrimaryColor => _companyPrimaryColor;

  // --- LOADING ---
  bool _isQrLoading = false;
  bool _isSummaryLoading = false;

  // --- GETTERS ---
  String? get qrSvg => _qrSvg;
  String? get error => _error;

  bool get isLoading => _isQrLoading || _isSummaryLoading;
  bool get hasError => _error != null;
  bool get hasQrCode => _qrSvg != null && _qrSvg!.isNotEmpty;
  bool get isReady => _status == CardStatus.hasCard && hasQrCode;

  // --- METHODS ---
  Future<void> loadCardSummary() async {
    _isSummaryLoading = true;
    _status = CardStatus.loading;
    notifyListeners();

    try {
      final res = await ApiClient.dio.get('/me/card-summary');
      debugPrint('📦 Card Summary Response: \\${res.data}');

      if (res.data['job_title'] == null && res.data['company'] == null) {
        _status = CardStatus.noCard;
        jobTitle = null;
        company = null;
        _theme = null;
      } else {
        jobTitle = res.data['job_title'];
        company = res.data['company'];
        phone = res.data['phone'];
        email = res.data['email'];
        linkedin = res.data['linkedin'];

        website = res.data['website'];
        github = res.data['github'];
        instagram = res.data['instagram'];
        facebook = res.data['facebook'];

        experiences = res.data['experiences'] ?? [];
        educations = res.data['educations'] ?? [];

        plan = res.data['plan'];

        scanCount = res.data['scan_count'] as int?;
        shareCount = res.data['share_count'] as int?;

        // Recuperer le slug et l'URL de partage
        _slug = res.data['slug'] as String?;
        _shareUrl = res.data['share_url'] as String?;
        debugPrint('🔗 Slug = $_slug');
        debugPrint('🔗 Share URL = $_shareUrl');

        _theme = res.data['theme'];
        debugPrint('🎨 Theme from API = $_theme');

        // Récupérer les infos de l'entreprise depuis l'objet branding
        final branding = res.data['branding'] as Map<String, dynamic>?;
        if (branding != null) {
          // Construire l'URL complète du logo
          final logoPath = branding['logo'] as String?;
          if (logoPath != null && logoPath.isNotEmpty) {
            // Si c'est déjà une URL complète, l'utiliser directement
            if (logoPath.startsWith('http://') ||
                logoPath.startsWith('https://')) {
              _companyLogo = logoPath;
            } else {
              // Sinon, construire l'URL avec le storage
              _companyLogo = '${ApiEndpoints.storageUrl}/$logoPath';
            }
          } else {
            _companyLogo = null;
          }
          _companyPrimaryColor = branding['primary_color'];
          // Utiliser le nom de l'entreprise du branding si disponible
          if (branding['company_name'] != null) {
            company = branding['company_name'];
          }
        } else {
          // Fallback sur les anciennes clés si branding n'existe pas
          final logoPath = res.data['company_logo'] as String?;
          if (logoPath != null && logoPath.isNotEmpty) {
            if (logoPath.startsWith('http://') ||
                logoPath.startsWith('https://')) {
              _companyLogo = logoPath;
            } else {
              _companyLogo = '${ApiEndpoints.storageUrl}/$logoPath';
            }
          } else {
            _companyLogo = null;
          }
          _companyPrimaryColor = res.data['company_primary_color'];
        }

        debugPrint('🏢 Company Logo = $_companyLogo');
        debugPrint('🎨 Company Color = $_companyPrimaryColor');
        debugPrint(
            '🏢 Is Company User = ${_companyLogo != null || _companyPrimaryColor != null}');

        _status = CardStatus.hasCard;
      }
    } catch (e) {
      debugPrint('❌ Error loading card summary: $e');
      _status = CardStatus.error;
      _error = 'Impossible de charger le résumé de la carte';
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyCardQr() async {
    _error = null;
    _isQrLoading = true;
    notifyListeners();

    try {
      _qrSvg = await CardService.getCardQrCode();
    } catch (e) {
      _qrSvg = null;
      _error = 'Erreur lors du chargement du QR code';
    } finally {
      _isQrLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTheme(String theme) async {
    try {
      await ApiClient.dio.put(
        '/me/card-summary',
        data: {'theme': theme},
      );

      _theme = theme;
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw ThemeForbiddenException(
          e.response?.data['message'] ?? 'Thème réservé aux comptes PRO',
        );
      }

      throw Exception('Erreur lors du changement de thème');
    }
  }

  void clearCard() {
    _qrSvg = null;
    _error = null;

    jobTitle = null;
    company = null;
    phone = null;
    email = null;
    linkedin = null;
    _companyLogo = null;
    _companyPrimaryColor = null;

    _status = CardStatus.idle;
    notifyListeners();
  }
}

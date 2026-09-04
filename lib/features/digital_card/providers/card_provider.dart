import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/services/card_service.dart';

import 'package:dio/dio.dart';

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
  String? bio;
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

  // --- PERSONAL BRANDING ---
  String? _accentColor;
  String? _logo;
  String? get accentColor => _accentColor;
  String? get logo => _logo;

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

  /// Remet le provider à zéro — appelé à la déconnexion pour qu'un nouveau
  /// compte connecté sur le même appareil ne voie jamais, même un instant,
  /// les données du compte précédent (ce provider est un singleton qui
  /// persiste tant que l'app tourne, il n'est jamais recréé au logout).
  void reset() {
    _status = CardStatus.idle;
    _qrSvg = null;
    _error = null;
    jobTitle = null;
    company = null;
    bio = null;
    phone = null;
    email = null;
    linkedin = null;
    _theme = null;
    website = null;
    github = null;
    instagram = null;
    facebook = null;
    experiences = [];
    educations = [];
    plan = null;
    scanCount = null;
    shareCount = null;
    _slug = null;
    _shareUrl = null;
    _companyLogo = null;
    _companyPrimaryColor = null;
    _accentColor = null;
    _logo = null;
    _isQrLoading = false;
    _isSummaryLoading = false;
    notifyListeners();
  }

  // --- METHODS ---
  Future<void> loadCardSummary() async {
    _isSummaryLoading = true;
    _status = CardStatus.loading;
    notifyListeners();

    try {
      final res = await ApiClient.dio.get('/me/card-summary');
      debugPrint('📦 Card Summary Response: \\${res.data}');

      // 'has_card' est le champ faisant foi (présent depuis l'ajout de la
      // création automatique de carte à l'inscription) : une carte peut
      // exister avec poste/entreprise encore vides (juste après
      // vérification d'email), ce que l'ancien test job_title==null &&
      // company==null confondait à tort avec "aucune carte". Le fallback
      // ne sert qu'en cas de réponse mise en cache par une ancienne build.
      final hasCard = res.data['has_card'] as bool? ??
          !(res.data['job_title'] == null && res.data['company'] == null);

      if (!hasCard) {
        _status = CardStatus.noCard;
        jobTitle = null;
        company = null;
        _theme = null;
        _accentColor = null;
        _logo = null;
      } else {
        jobTitle = res.data['job_title'];
        company = res.data['company'];
        bio = res.data['bio'];
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

        _accentColor = res.data['accent_color'] as String?;
        final personalLogoPath = res.data['logo'] as String?;
        if (personalLogoPath != null && personalLogoPath.isNotEmpty) {
          _logo = personalLogoPath.startsWith('http')
              ? personalLogoPath
              : '${ApiEndpoints.storageUrl}/$personalLogoPath';
        } else {
          _logo = null;
        }

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

  /// Personnalise la carte (couleur d'accent + logo), gratuit pour tous.
  Future<void> updatePersonalBranding({
    String? accentColorHex,
    String? localLogoPath,
    bool removeLogo = false,
  }) async {
    try {
      final formData = FormData.fromMap({
        '_method': 'PUT',
        if (accentColorHex != null) 'accent_color': accentColorHex,
        // Laravel valide 'remove_logo' avec la règle stricte 'boolean', qui
        // n'accepte que 1/0/true/false/"1"/"0" — pas la chaîne "true" que
        // Dio produit si on passe un bool Dart brut dans FormData.fromMap.
        if (removeLogo) 'remove_logo': '1',
      });

      if (localLogoPath != null && !localLogoPath.startsWith('http')) {
        final file = File(localLogoPath);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'logo',
            await MultipartFile.fromFile(
              localLogoPath,
              filename: localLogoPath.split('/').last,
            ),
          ));
        }
      }

      await ApiClient.dio.post(
        '/me/card-summary',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      await loadCardSummary();
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e,
          fallback: 'Erreur lors de la personnalisation de la carte'));
    }
  }

  void clearCard() {
    _qrSvg = null;
    _error = null;

    jobTitle = null;
    company = null;
    bio = null;
    phone = null;
    email = null;
    linkedin = null;
    _companyLogo = null;
    _companyPrimaryColor = null;
    _accentColor = null;
    _logo = null;

    _status = CardStatus.idle;
    notifyListeners();
  }
}

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import 'device_info_service.dart';

class CardService {
  static const String _qrEndpoint = '/me/card/qr';
  static const String _shareEndpoint = '/me/card/share';
  static const String _shareLogEndpoint = '/me/card/share-log';
  static const String _leadsEndpoint = '/me/card/leads';
  static const String _highlightEndpoint = '/highlights';


/// Contexte de création/édition de carte : indique si le champ entreprise
/// doit être verrouillé (utilisateur rattaché à une entreprise).
static Future<Map<String, dynamic>> getCreateContext() async {
  try {
    final response = await ApiClient.dio.get('/cards/create-context');

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    return {'company_locked': false, 'company': null};
  } on DioException catch (e) {
    debugPrint('⚠️ Erreur create-context (non bloquante): ${e.message}');
    return {'company_locked': false, 'company': null};
  }
}

static Future<Map<String, dynamic>> getCardSummary() async {
  final response = await ApiClient.dio.get('/me/card-summary');

  if (response.data == null || response.data is! Map<String, dynamic>) {
    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Résumé de carte invalide',
      type: DioExceptionType.unknown,
    );
  }

  return response.data as Map<String, dynamic>;
}

static Future<void> createCard({
  required String jobTitle,
  required String company,
  String? firstname,
  String? lastname,
  String? phone,
  String? email,
  String? linkedin,
  String? companyAddress,
  String? companyPhone,
  String? companyEmail,
  required List<String> activatedFields,
  bool isPublic = true,
}) async {
  await ApiClient.dio.post(
    '/digital-card',
    data: {
      'job_title': jobTitle,
      'company': company,
      if (firstname != null && firstname.isNotEmpty) 'firstname': firstname,
      if (lastname != null && lastname.isNotEmpty) 'lastname': lastname,
      'phone': phone,
      'email': email,
      'linkedin': linkedin,
      if (companyAddress != null && companyAddress.isNotEmpty) 'company_address': companyAddress,
      if (companyPhone != null && companyPhone.isNotEmpty) 'company_phone': companyPhone,
      if (companyEmail != null && companyEmail.isNotEmpty) 'company_email': companyEmail,
      'activated_fields': activatedFields,
      'is_public': isPublic,
    },
  );
}



  /// Récupère un lien public de partage pour la carte de l'utilisateur.
  ///
  /// Le backend doit fournir un endpoint sécurisé renvoyant JSON { "url": "https://..." }.
  /// Si l'endpoint n'existe pas ou retourne une erreur, la méthode propagera une DioException.
  static Future<String> getCardShareLink() async {
    try {
      final response = await ApiClient.dio.get(_shareEndpoint);

      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Lien de partage introuvable',
          type: DioExceptionType.unknown,
        );
      }

      // Support both Map and plain string responses
      if (response.data is String && (response.data as String).isNotEmpty) {
        return response.data as String;
      }

      if (response.data is Map && response.data['url'] != null) {
        return response.data['url'] as String;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Format de réponse inattendu pour le lien de partage',
        type: DioExceptionType.unknown,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Récupère le QR code SVG de la carte digitale de l'utilisateur connecté.
  ///
  /// Effectue un appel GET sécurisé vers [_qrEndpoint] avec le token Bearer.
  /// La réponse est un SVG en String.
  ///
  /// Throws:
  /// - [DioException] avec statusCode 401 si le token est invalide/expiré
  /// - [DioException] avec statusCode 403 si l'accès est refusé
  /// - [DioException] avec statusCode 500 en cas d'erreur serveur
  /// - [DioException] pour autres erreurs réseau/parsing
  ///
  /// Returns: Le SVG QR code en String
  static Future<String> getCardQrCode() async {
  try {
    final response = await ApiClient.dio.get(_qrEndpoint);

    final data = response.data;
    if (data == null || data['qr'] == null || data['qr'].isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'QR code SVG vide reçu du serveur',
        type: DioExceptionType.unknown,
      );
    }

    return data['qr'] as String;
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

  /// Retrieve a public card by its slug (e.g. 'adama-dabo').
  /// Example endpoint: GET /api/cards/{slug}
  static Future<Map<String, dynamic>> getPublicCard(String slug) async {
    try {
      final endpoint = '/cards/$slug';
      final response = await ApiClient.dio.get(endpoint);

      if (response.data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Carte introuvable',
          type: DioExceptionType.unknown,
        );
      }

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      // Some backends may return JSON encoded as String
      if (response.data is String && (response.data as String).isNotEmpty) {
        try {
          final parsed = response.data as String;
          final decoded = json.decode(parsed);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (_) {
          throw DioException(
            requestOptions: response.requestOptions,
            error: 'Format de réponse invalide',
            type: DioExceptionType.unknown,
          );
        }
      }

      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Format de réponse inattendu',
        type: DioExceptionType.unknown,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Traite les erreurs DIO et les convertit en exceptions significatives.
  ///
  /// Gère les cas:
  /// - 401: Token invalide/expiré
  /// - 403: Accès refusé (permissions manquantes)
  /// - 500: Erreur serveur
  /// - Autres: Erreurs réseau/timeout
  static void _handleError(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 401:
        // Token invalide ou expiré - à gérer dans l'app pour rediriger vers login
        throw DioException(
          requestOptions: error.requestOptions,
          error: 'Token invalide ou expiré. Veuillez vous reconnecter.',
          type: error.type,
          response: error.response,
        );
      case 403:
        // Accès refusé
        throw DioException(
          requestOptions: error.requestOptions,
          error: 'Accès refusé. Vous n\'avez pas les permissions nécessaires.',
          type: error.type,
          response: error.response,
        );
      case 500:
        // Erreur serveur
        throw DioException(
          requestOptions: error.requestOptions,
          error: 'Erreur serveur. Veuillez réessayer plus tard.',
          type: error.type,
          response: error.response,
        );
      default:
        // Autres erreurs (timeout, connexion, parsing, etc.)
        if (error.type == DioExceptionType.connectionTimeout) {
          throw DioException(
            requestOptions: error.requestOptions,
            error: 'Timeout de connexion. Vérifiez votre connexion internet.',
            type: error.type,
          );
        } else if (error.type == DioExceptionType.unknown) {
          throw DioException(
            requestOptions: error.requestOptions,
            error: 'Erreur réseau: ${error.error}',
            type: error.type,
          );
        } else {
          throw error;
        }
    }
  }

  static Future<List<Map<String, dynamic>>> fetchHighlights() async {
  try {
    final response = await ApiClient.dio.get(_highlightEndpoint);

    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Format de highlights invalide',
      type: DioExceptionType.unknown,
    );
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

static Future<Map<String, dynamic>> createHighlight(String name) async {
  try {
    final response = await ApiClient.dio.post(
      _highlightEndpoint,
      data: {'name': name},
    );

    if (response.data is Map<String, dynamic>) {
      return response.data;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      error: 'Erreur création highlight',
      type: DioExceptionType.unknown,
    );
  } on DioException catch (e) {
    // Log détaillé pour débugger
    debugPrint('❌ Erreur création highlight:');
    debugPrint('   Status: ${e.response?.statusCode}');
    debugPrint('   Data: ${e.response?.data}');
    debugPrint('   Message: ${e.message}');
    _handleError(e);
    rethrow;
  }
}

static Future<void> activateHighlight(int highlightId) async {
  try {
    await ApiClient.dio.post(
      '$_highlightEndpoint/$highlightId/activate',
    );
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

static Future<void> deactivateHighlight(int highlightId) async {
  try {
    await ApiClient.dio.post(
      '$_highlightEndpoint/$highlightId/deactivate',
    );
  } on DioException catch (e) {
    _handleError(e);
    rethrow;
  }
}

  /// Enregistre un partage de carte avec le canal utilisé
  /// [channel] : whatsapp, email, sms, linkedin, copy, other
  /// [message] : Le message personnalisé envoyé (optionnel)
  /// Note: Cette méthode ne propage pas les erreurs pour ne pas bloquer le partage
  static Future<void> logShare({
    required String channel,
    String? message,
  }) async {
    try {
      await ApiClient.dio.post(
        _shareLogEndpoint,
        data: {
          'channel': channel,
          if (message != null) 'message': message,
        },
      );
    } on DioException catch (e) {
      // Log l'erreur silencieusement pour ne pas bloquer le partage
      debugPrint('⚠️ Erreur log partage (non bloquante): ${e.message}');
    } catch (e) {
      debugPrint('⚠️ Erreur log partage: $e');
    }
  }

  /// Récupère la liste des leads (personnes ayant scanné/vu la carte)
  static Future<Map<String, dynamic>> getLeads() async {
    try {
      final response = await ApiClient.dio.get(_leadsEndpoint);

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Format de réponse invalide pour les leads',
        type: DioExceptionType.unknown,
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Enregistre une vue/lead sur une carte publique
  /// Appelé depuis la page publique quand quelqu'un scanne le QR
  /// Collecte automatiquement les informations de l'appareil
  static Future<Map<String, dynamic>> registerCardView({
    required String slug,
    String? name,
    String? email,
    String? phone,
    String source = 'qr_scan',
  }) async {
    try {
      // Collecter automatiquement les informations de l'appareil
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      final userAgent = await DeviceInfoService.getUserAgent();

      debugPrint('📱 Device info collected:');
      debugPrint('   Device: ${deviceInfo['device']}');
      debugPrint('   Platform: ${deviceInfo['platform']}');
      debugPrint('   User Agent: $userAgent');

      final requestData = {
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'source': source,
        // Informations collectées automatiquement
        'device': deviceInfo['device'],
        'platform': deviceInfo['platform'],
        'user_agent': userAgent,
      };

      debugPrint('📤 Sending view registration to /cards/$slug/view');
      debugPrint('   Data: $requestData');

      final response = await ApiClient.dio.post(
        '/cards/$slug/view',
        data: requestData,
      );

      debugPrint('✅ View registration successful');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      return {'success': true};
    } on DioException catch (e) {
      debugPrint('❌ Error registering view:');
      debugPrint('   Status: ${e.response?.statusCode}');
      debugPrint('   Response: ${e.response?.data}');
      debugPrint('   Message: ${e.message}');
      _handleError(e);
      rethrow;
    }
  }
}

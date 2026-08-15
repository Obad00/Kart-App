import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class PublicCardService {
  // Accès direct au Dio statique
  final Dio _dio = ApiClient.dio;

  Future<Map<String, dynamic>?> fetchCard(String slug) async {
    final response = await _dio.get('/cards/$slug');
    if (response.statusCode == 200) {
      final data = response.data;
      final Map<String, dynamic> result;

      if (data is Map<String, dynamic>) {
        result = Map<String, dynamic>.from(data);
      } else if (data is String) {
        result = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        return null;
      }

      final socialKeys = [
        'email',
        'linkedin',
        'instagram',
        'facebook',
        'github',
        'website',
        'x',
      ];

      // Le backend renvoie toujours la valeur brute de chaque champ (même
      // désactivé) — 'activated_fields' est la liste de ceux que le
      // propriétaire a choisi d'afficher publiquement. Sans ce filtre, un
      // réseau désactivé restait visible tant que sa valeur n'était pas
      // effacée, pas seulement décochée.
      final activated = (result['activated_fields'] as List?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      if (result['fields'] == null) {
        final builtFields = <String, dynamic>{};
        for (final key in socialKeys) {
          final val = result[key];
          if (val != null &&
              val.toString().isNotEmpty &&
              activated.contains(key)) {
            builtFields[key] = val;
          }
        }
        if (result['phone'] != null &&
            result['phone'].toString().isNotEmpty &&
            activated.contains('phone')) {
          builtFields['phone'] = result['phone'];
        }
        result['fields'] = builtFields;
      }

      return result;
    }
    return null;
  }

  /// Envoie un message au propriétaire de la carte publique [slug].
  /// Lève une [DioException] en cas d'échec (réseau, validation, etc.).
  Future<void> contactCardOwner({
    required String slug,
    required String name,
    required String email,
    required String message,
  }) async {
    final response = await _dio.post(
      '/cards/$slug/contact',
      data: {
        'name': name,
        'email': email,
        'message': message,
      },
    );

    if (response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: "Erreur lors de l'envoi du message",
      );
    }
  }
}

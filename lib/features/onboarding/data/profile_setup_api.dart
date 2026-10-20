import '../../../core/network/api_client.dart';

/// Lecture et enregistrement de la carte pendant l'onboarding. Envoie
/// seulement les champs de l'étape : jamais l'e-mail, qui changerait
/// l'adresse de connexion (cf. AccountEmailService côté backend).
class ProfileSetupApi {
  const ProfileSetupApi();

  Future<Map<String, dynamic>> fetchCard() async {
    final res = await ApiClient.dio.get('/me/card-summary');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> saveCard(Map<String, dynamic> fields) async {
    await ApiClient.dio.put('/me/card-summary', data: fields);
  }
}

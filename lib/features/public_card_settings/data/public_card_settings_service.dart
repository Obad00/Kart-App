import '../../../core/network/api_client.dart';
import '../models/public_card_settings.dart';

/// Appels de l'écran « Personnaliser ma carte publique ».
class PublicCardSettingsService {
  const PublicCardSettingsService();

  Future<PublicCardSettingsData> fetch() async {
    final response = await ApiClient.dio.get('/me/card/public-settings');
    return _parse(response.data);
  }

  /// Disposition, thème, style, ordre et sections masquées.
  Future<PublicCardSettingsData> save(PublicCardSettings settings) async {
    final response = await ApiClient.dio
        .put('/me/card/public-settings', data: settings.toJson());
    return _parse(response.data);
  }

  /// Visibilité du téléphone, de l'email, des réseaux et du site : même
  /// champ (`activated_fields`) et même endpoint que le formulaire
  /// « Modifier mes infos ».
  ///
  /// La couleur d'accent passe par le même champ (`accent_color`) que la
  /// feuille « Couleur et logo » : une seule donnée, deux accès. Seules
  /// les valeurs fournies sont envoyées.
  Future<void> saveCard({List<String>? activatedFields, String? accentHex}) async {
    await ApiClient.dio.put('/me/card-summary', data: {
      if (activatedFields != null) 'activated_fields': activatedFields,
      if (accentHex != null) 'accent_color': accentHex,
    });
  }

  PublicCardSettingsData _parse(Object? data) {
    if (data is! Map) {
      throw const FormatException('Réponse inattendue du serveur');
    }
    return PublicCardSettingsData.fromJson(Map<String, dynamic>.from(data));
  }
}

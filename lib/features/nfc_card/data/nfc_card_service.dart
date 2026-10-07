import '../../../core/network/api_client.dart';
import '../models/nfc_card_status.dart';

/// Appels de l'écran « Ma carte NFC ». Chaque appel renvoie l'état complet
/// à jour, pour rafraîchir l'écran sans second aller-retour.
class NfcCardService {
  const NfcCardService();

  Future<NfcCardStatus> fetch() async {
    final response = await ApiClient.dio.get('/me/nfc');
    return _parse(response.data);
  }

  /// Commande d'une carte. Aucun paiement dans l'app : KART recontacte
  /// l'utilisateur.
  Future<NfcCardStatus> order({
    required String phone,
    required String address,
    String? notes,
  }) async {
    final response = await ApiClient.dio.post('/me/nfc/orders', data: {
      'delivery_phone': phone,
      'delivery_address': address,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return _parse(response.data);
  }

  /// Active (ou réactive) la carte dont on donne le code : celui lu sur la
  /// puce, ou saisi à la main. C'est la preuve qu'on l'a en main.
  Future<NfcCardStatus> activate(String code) async {
    final response =
        await ApiClient.dio.post('/me/nfc/activate', data: {'code': code});
    return _parse(response.data);
  }

  /// Carte perdue : son lien cesse d'ouvrir la carte de visite.
  Future<NfcCardStatus> disable(int tagId) async {
    final response = await ApiClient.dio
        .patch('/me/nfc/$tagId', data: {'status': 'disabled'});
    return _parse(response.data);
  }

  NfcCardStatus _parse(Object? data) {
    if (data is! Map) {
      throw const FormatException('Réponse inattendue du serveur');
    }
    return NfcCardStatus.fromJson(Map<String, dynamic>.from(data));
  }
}

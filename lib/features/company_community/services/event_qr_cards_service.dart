import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// Un modèle de QR de l'événement (cf. EventQrCardService côté backend).
class EventQrModel {
  final String key;
  final String label;
  final String hint;

  const EventQrModel(this.key, this.label, this.hint);
}

/// QR de check-in de l'événement en 5 modèles, PNG ou PDF, pour
/// l'organisateur : à imprimer ou afficher à l'accueil.
class EventQrCardsService {
  static const models = [
    EventQrModel('classique', 'Classique', 'Fond blanc, A5'),
    EventQrModel('sombre', 'Sombre', 'Noir mat, A5'),
    EventQrModel('couleur', 'Couleur', 'Vos couleurs, A5'),
    EventQrModel('affiche', 'Affiche', 'Affiche floutée, A5'),
    EventQrModel('chevalet', 'Chevalet', 'A4 à plier, sur table'),
  ];

  Future<Uint8List> fetch(int eventId, String model, {String format = 'png'}) async {
    final response = await ApiClient.dio.get<List<int>>(
      '/events/$eventId/qr-card',
      queryParameters: {'model': model, 'format': format},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}

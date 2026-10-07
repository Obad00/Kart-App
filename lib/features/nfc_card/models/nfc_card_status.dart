/// État de l'écran « Ma carte NFC », calculé par le serveur (GET /me/nfc).
enum NfcCardState {
  /// Aucune carte NFC, aucune commande en cours.
  none,

  /// Commande en cours de préparation.
  ordered,

  /// Carte attribuée par KART, à activer par l'utilisateur.
  ready,

  /// Carte active : la taper ouvre la carte de visite.
  active,

  /// Carte désactivée (perdue) : son lien n'ouvre plus rien.
  disabled,
}

/// Étapes d'une commande, dans l'ordre de la frise.
enum NfcOrderStatus { pending, inProduction, ready, delivered, cancelled }

class NfcTagInfo {
  final int id;

  /// null tant que la carte n'est pas activée : il faut l'avoir en main
  /// (tap ou saisie) pour le connaître.
  final String? code;
  final int tapCount;
  final DateTime? lastTappedAt;

  /// false si c'est KART qui a désactivé la carte : seul le support peut
  /// alors la réactiver.
  final bool canReactivate;

  const NfcTagInfo({
    required this.id,
    this.code,
    this.tapCount = 0,
    this.lastTappedAt,
    this.canReactivate = false,
  });

  factory NfcTagInfo.fromJson(Map<String, dynamic> json) => NfcTagInfo(
        id: (json['id'] as num).toInt(),
        code: json['code'] as String?,
        tapCount: (json['tap_count'] as num?)?.toInt() ?? 0,
        lastTappedAt: _date(json['last_tapped_at']),
        canReactivate: json['can_reactivate'] == true,
      );
}

class NfcOrderInfo {
  final int id;
  final NfcOrderStatus status;
  final String deliveryPhone;
  final String deliveryAddress;
  final String? notes;
  final DateTime? createdAt;

  const NfcOrderInfo({
    required this.id,
    required this.status,
    this.deliveryPhone = '',
    this.deliveryAddress = '',
    this.notes,
    this.createdAt,
  });

  factory NfcOrderInfo.fromJson(Map<String, dynamic> json) => NfcOrderInfo(
        id: (json['id'] as num).toInt(),
        status: _orderStatus(json['status'] as String?),
        deliveryPhone: json['delivery_phone'] as String? ?? '',
        deliveryAddress: json['delivery_address'] as String? ?? '',
        notes: json['notes'] as String?,
        createdAt: _date(json['created_at']),
      );

  static NfcOrderStatus _orderStatus(String? value) => switch (value) {
        'in_production' => NfcOrderStatus.inProduction,
        'ready' => NfcOrderStatus.ready,
        'delivered' => NfcOrderStatus.delivered,
        'cancelled' => NfcOrderStatus.cancelled,
        _ => NfcOrderStatus.pending,
      };
}

class NfcCardStatus {
  final NfcCardState state;

  /// false si l'utilisateur n'a pas encore de carte digitale : rien à
  /// relier à une carte NFC.
  final bool hasCard;

  /// Numéro WhatsApp du support, chiffres seuls (prêt pour wa.me). null :
  /// le bouton « Contacter le support » est masqué.
  final String? supportWhatsapp;
  final NfcTagInfo? tag;
  final NfcOrderInfo? order;

  /// Dernière commande, si elle a été annulée par KART.
  final NfcOrderInfo? cancelledOrder;

  const NfcCardStatus({
    required this.state,
    this.hasCard = true,
    this.supportWhatsapp,
    this.tag,
    this.order,
    this.cancelledOrder,
  });

  factory NfcCardStatus.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? map(String key) {
      final value = json[key];
      return value is Map ? Map<String, dynamic>.from(value) : null;
    }

    final tag = map('tag');
    final order = map('order');
    final cancelled = map('cancelled_order');
    final whatsapp = (json['support_whatsapp'] as String?)?.trim();

    return NfcCardStatus(
      state: _state(json['state'] as String?),
      hasCard: json['has_card'] != false,
      supportWhatsapp: whatsapp == null || whatsapp.isEmpty ? null : whatsapp,
      tag: tag == null ? null : NfcTagInfo.fromJson(tag),
      order: order == null ? null : NfcOrderInfo.fromJson(order),
      cancelledOrder: cancelled == null ? null : NfcOrderInfo.fromJson(cancelled),
    );
  }

  /// Un état inconnu (app plus ancienne que le serveur) retombe sur
  /// « aucune carte » plutôt que de planter.
  static NfcCardState _state(String? value) => switch (value) {
        'ordered' => NfcCardState.ordered,
        'ready' => NfcCardState.ready,
        'active' => NfcCardState.active,
        'disabled' => NfcCardState.disabled,
        _ => NfcCardState.none,
      };
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

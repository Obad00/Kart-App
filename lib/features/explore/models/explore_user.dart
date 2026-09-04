enum ConnectionStatus { none, pendingSent, pendingReceived }

class ExploreUser {
  final int id;
  final String name;
  final String? jobTitle;
  final String? company;
  final String? city;
  final String? avatar;
  final String? cardSlug;
  final ConnectionStatus connectionStatus;
  // Présent seulement quand connectionStatus != none — permet d'accepter/
  // refuser directement dans l'app (pas seulement depuis le mail).
  final int? connectionRequestId;
  // 0-100, même calcul que le Kart Score du profil (cf. CompletionHelper)
  // — le backend trie déjà l'annuaire par score décroissant ; ce champ ne
  // sert ici qu'à afficher le badge "Profil complet" (>= 90).
  final int completionScore;
  // Inscrit il y a 14 jours ou moins (cf. ExploreController::index) —
  // badge "Nouveau" sur "Nouveaux profils sur KART".
  final bool isNew;

  ExploreUser({
    required this.id,
    required this.name,
    this.jobTitle,
    this.company,
    this.city,
    this.avatar,
    this.cardSlug,
    this.connectionStatus = ConnectionStatus.none,
    this.connectionRequestId,
    this.completionScore = 0,
    this.isNew = false,
  });

  bool get hasCompleteProfile => completionScore >= 90;

  factory ExploreUser.fromJson(Map<String, dynamic> json) {
    return ExploreUser(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      jobTitle: json['jobTitle'],
      company: json['company'],
      city: json['city'],
      avatar: json['avatar'],
      cardSlug: json['cardSlug'],
      connectionStatus: _statusFromJson(json['connectionStatus']),
      connectionRequestId: json['connectionRequestId'] != null
          ? int.tryParse(json['connectionRequestId'].toString())
          : null,
      completionScore:
          int.tryParse(json['completionScore']?.toString() ?? '') ?? 0,
      isNew: json['isNew'] == true,
    );
  }

  static ConnectionStatus _statusFromJson(dynamic value) {
    switch (value) {
      case 'pending_sent':
        return ConnectionStatus.pendingSent;
      case 'pending_received':
        return ConnectionStatus.pendingReceived;
      default:
        return ConnectionStatus.none;
    }
  }

  ExploreUser copyWith({
    ConnectionStatus? connectionStatus,
    int? connectionRequestId,
  }) {
    return ExploreUser(
      id: id,
      name: name,
      jobTitle: jobTitle,
      company: company,
      city: city,
      avatar: avatar,
      cardSlug: cardSlug,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionRequestId: connectionRequestId ?? this.connectionRequestId,
      completionScore: completionScore,
      isNew: isNew,
    );
  }

  /// Remet la relation à zéro (ex: après annulation d'une demande envoyée)
  /// — distinct de copyWith car `?? this.connectionRequestId` empêcherait
  /// de repasser l'id à null.
  ExploreUser clearConnection() {
    return ExploreUser(
      id: id,
      name: name,
      jobTitle: jobTitle,
      company: company,
      city: city,
      avatar: avatar,
      cardSlug: cardSlug,
      connectionStatus: ConnectionStatus.none,
      connectionRequestId: null,
      completionScore: completionScore,
      isNew: isNew,
    );
  }
}

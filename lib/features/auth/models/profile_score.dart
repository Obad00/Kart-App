/// Score de profil calculé par le serveur (champ `profile_score` de /me,
/// cf. ProfileScoreService) : la seule source, la même que l'admin et
/// l'Explorer.
class ProfileScore {
  const ProfileScore({required this.score, required this.criteria, this.next});

  final int score;
  final List<ProfileCriterion> criteria;

  /// Élément manquant à compléter en premier (le plus lourd), null si 100 %.
  final ProfileCriterion? next;

  bool get isComplete => score >= 100 || next == null;

  static ProfileScore? fromJson(Object? json) {
    if (json is! Map) return null;
    final criteria = (json['criteria'] as List? ?? [])
        .whereType<Map>()
        .map((c) => ProfileCriterion.fromJson(Map<String, dynamic>.from(c)))
        .toList();
    final next = json['next'] is Map ? ProfileCriterion.fromJson(Map<String, dynamic>.from(json['next'] as Map)) : null;
    return ProfileScore(score: (json['score'] as num?)?.toInt() ?? 0, criteria: criteria, next: next);
  }
}

class ProfileCriterion {
  const ProfileCriterion({required this.key, required this.label, required this.weight, this.done = false});

  /// photo, job_title, contact, company, bio, link, skills, experience,
  /// education.
  final String key;
  final String label;
  final int weight;
  final bool done;

  factory ProfileCriterion.fromJson(Map<String, dynamic> json) => ProfileCriterion(
        key: json['key']?.toString() ?? '',
        label: json['label']?.toString() ?? '',
        weight: (json['weight'] as num?)?.toInt() ?? 0,
        done: json['done'] == true,
      );
}

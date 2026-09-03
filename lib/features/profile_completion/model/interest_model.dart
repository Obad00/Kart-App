/// Une suggestion du référentiel de centres d'intérêt (cf.
/// InterestController côté backend) — même principe que SkillSuggestion.
/// Le champ reste du texte libre : cette classe ne sert qu'à peupler
/// l'autocomplete de InterestsEditorSheet, pas à contraindre la saisie.
class InterestSuggestion {
  final int id;
  final String name;
  final String? category;

  InterestSuggestion({required this.id, required this.name, this.category});

  factory InterestSuggestion.fromJson(Map<String, dynamic> json) {
    return InterestSuggestion(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'],
    );
  }
}

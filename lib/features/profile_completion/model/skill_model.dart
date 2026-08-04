class CandidateSkillModel {
  int? id;
  String name;
  final String? category;
  String level;
  int? years;

  CandidateSkillModel({
    this.id,
    required this.name,
    this.category,
    this.level = 'intermediaire',
    this.years,
  });

  factory CandidateSkillModel.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'] as Map<String, dynamic>?;
    return CandidateSkillModel(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'],
      level: pivot?['level'] ?? 'intermediaire',
      years: pivot?['years'],
    );
  }

  factory CandidateSkillModel.fromSuggestion(
    SkillSuggestion suggestion, {
    String level = 'intermediaire',
  }) {
    return CandidateSkillModel(
      id: suggestion.id,
      name: suggestion.name,
      category: suggestion.category,
      level: level,
    );
  }

  Map<String, dynamic> toPayload() {
    return id != null
        ? {'id': id, 'level': level, 'years': years}
        : {'name': name, 'level': level, 'years': years};
  }
}

class SkillSuggestion {
  final int id;
  final String name;
  final String? category;

  SkillSuggestion({required this.id, required this.name, this.category});

  factory SkillSuggestion.fromJson(Map<String, dynamic> json) {
    return SkillSuggestion(
      id: json['id'],
      name: json['name'] ?? '',
      category: json['category'],
    );
  }
}

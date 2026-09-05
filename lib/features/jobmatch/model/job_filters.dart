/// Sélection courante des filtres du fil JobMatch — immuable, toujours
/// remplacée via copyWith()/JobMatchFilters() plutôt que mutée en place, pour
/// que JobMatchProvider sache quand relancer loadFeed().
class JobMatchFilters {
  final int? categoryId;
  final String? categoryName;
  final String? location;
  final bool remoteOnly;
  final String? contractType;
  final int? minExperience;
  final int? minSalary;
  final List<int> skillIds;
  final List<String> skillNames;

  /// Nombre de jours (offres publiées dans les N derniers jours) — null =
  /// "Indifférent".
  final int? publishedWithinDays;

  const JobMatchFilters({
    this.categoryId,
    this.categoryName,
    this.location,
    this.remoteOnly = false,
    this.contractType,
    this.minExperience,
    this.minSalary,
    this.skillIds = const [],
    this.skillNames = const [],
    this.publishedWithinDays,
  });

  bool get isEmpty =>
      categoryId == null &&
      location == null &&
      !remoteOnly &&
      contractType == null &&
      minExperience == null &&
      minSalary == null &&
      skillIds.isEmpty &&
      publishedWithinDays == null;

  int get activeCount => [
        categoryId != null,
        location != null,
        remoteOnly,
        contractType != null,
        minExperience != null,
        minSalary != null,
        skillIds.isNotEmpty,
        publishedWithinDays != null,
      ].where((v) => v).length;

  Map<String, dynamic> toQueryParams() {
    return {
      if (categoryId != null) 'category': categoryId,
      if (location != null) 'location': location,
      if (remoteOnly) 'remote_only': true,
      if (contractType != null) 'contract_type': contractType,
      if (minExperience != null) 'min_experience': minExperience,
      if (minSalary != null) 'min_salary': minSalary,
      // 'skill_ids[]' (pas 'skill_ids') : Dio sérialise une List en
      // répétant la clé (skill_ids=1&skill_ids=2), que Laravel n'assemble
      // en tableau que si la clé porte les crochets — sans eux, seule la
      // dernière valeur arrivait côté serveur.
      if (skillIds.isNotEmpty) 'skill_ids[]': skillIds,
      if (publishedWithinDays != null)
        'published_within_days': publishedWithinDays,
    };
  }

  JobMatchFilters copyWith({
    int? categoryId,
    String? categoryName,
    String? location,
    bool? remoteOnly,
    String? contractType,
    int? minExperience,
    int? minSalary,
    List<int>? skillIds,
    List<String>? skillNames,
    int? publishedWithinDays,
    bool clearCategory = false,
    bool clearLocation = false,
    bool clearContractType = false,
    bool clearMinExperience = false,
    bool clearMinSalary = false,
    bool clearPublishedWithinDays = false,
  }) {
    return JobMatchFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      location: clearLocation ? null : (location ?? this.location),
      remoteOnly: remoteOnly ?? this.remoteOnly,
      contractType:
          clearContractType ? null : (contractType ?? this.contractType),
      minExperience:
          clearMinExperience ? null : (minExperience ?? this.minExperience),
      minSalary: clearMinSalary ? null : (minSalary ?? this.minSalary),
      skillIds: skillIds ?? this.skillIds,
      skillNames: skillNames ?? this.skillNames,
      publishedWithinDays: clearPublishedWithinDays
          ? null
          : (publishedWithinDays ?? this.publishedWithinDays),
    );
  }
}

class JobFilterOptions {
  final List<JobCategoryOption> categories;
  final List<String> locations;
  final List<String> contractTypes;
  final List<JobSkillOption> skills;

  JobFilterOptions({
    required this.categories,
    required this.locations,
    required this.contractTypes,
    required this.skills,
  });

  factory JobFilterOptions.fromJson(Map<String, dynamic> json) {
    return JobFilterOptions(
      categories: (json['categories'] as List? ?? [])
          .map((e) => JobCategoryOption.fromJson(e))
          .toList(),
      locations:
          (json['locations'] as List? ?? []).map((e) => e.toString()).toList(),
      contractTypes: (json['contractTypes'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      skills: (json['skills'] as List? ?? [])
          .map((e) => JobSkillOption.fromJson(e))
          .toList(),
    );
  }
}

class JobCategoryOption {
  final int id;
  final String name;

  JobCategoryOption({required this.id, required this.name});

  factory JobCategoryOption.fromJson(Map<String, dynamic> json) {
    return JobCategoryOption(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class JobSkillOption {
  final int id;
  final String name;

  JobSkillOption({required this.id, required this.name});

  factory JobSkillOption.fromJson(Map<String, dynamic> json) {
    return JobSkillOption(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
    );
  }
}

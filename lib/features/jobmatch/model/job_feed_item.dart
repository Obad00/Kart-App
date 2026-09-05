class JobFeedItem {
  final int id;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String? location;
  final bool isRemote;
  final String? contractType;
  final int? salaryMin;
  final int? salaryMax;
  final int score;
  final String? description;
  final int? experienceRequired;
  final DateTime? publishedAt;
  final bool isSaved;
  final String? category;
  final List<String> skills;

  JobFeedItem({
    required this.id,
    required this.title,
    required this.companyName,
    this.companyLogo,
    this.location,
    required this.isRemote,
    this.contractType,
    this.salaryMin,
    this.salaryMax,
    required this.score,
    this.description,
    this.experienceRequired,
    this.publishedAt,
    this.isSaved = false,
    this.category,
    this.skills = const [],
  });

  factory JobFeedItem.fromJson(Map<String, dynamic> json) {
    return JobFeedItem(
      id: json['id'],
      title: json['title'] ?? '',
      companyName: json['company']?['name'] ?? '',
      companyLogo: json['company']?['logo'],
      location: json['location'],
      isRemote: json['is_remote'] ?? false,
      contractType: json['contract_type'],
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      score: json['score'] ?? 0,
      description: json['description'],
      experienceRequired: json['experience_required'],
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
      isSaved: json['isSaved'] == true,
      category: json['category'],
      skills: (json['skills'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  /// Retourne une copie avec isSaved mis à jour — après un save/unsave
  /// réussi côté serveur, pour refléter l'état sans recharger tout le fil.
  JobFeedItem copyWithSaved(bool saved) {
    return JobFeedItem(
      id: id,
      title: title,
      companyName: companyName,
      companyLogo: companyLogo,
      location: location,
      isRemote: isRemote,
      contractType: contractType,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      score: score,
      description: description,
      experienceRequired: experienceRequired,
      publishedAt: publishedAt,
      isSaved: saved,
      category: category,
      skills: skills,
    );
  }
}

class JobMatchResult {
  final int id;
  final int score;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final String? location;
  final bool isRemote;
  final String? contractType;
  final int? salaryMin;
  final int? salaryMax;
  final String? description;
  final int? experienceRequired;
  final DateTime? publishedAt;
  final String? category;
  final List<String> skills;

  JobMatchResult({
    required this.id,
    required this.score,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    this.location,
    this.isRemote = false,
    this.contractType,
    this.salaryMin,
    this.salaryMax,
    this.description,
    this.experienceRequired,
    this.publishedAt,
    this.category,
    this.skills = const [],
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    final company = job?['company'];
    final companyName =
        company is Map ? (company['name'] ?? '') : (company ?? '');
    final companyLogo = company is Map ? company['logo'] : null;

    return JobMatchResult(
      id: json['id'],
      score: json['score'] ?? 0,
      jobTitle: job?['title'] ?? '',
      companyName: companyName?.toString() ?? '',
      companyLogo: companyLogo,
      location: job?['location'],
      isRemote: job?['is_remote'] ?? false,
      contractType: job?['contract_type'],
      salaryMin: job?['salary_min'],
      salaryMax: job?['salary_max'],
      description: job?['description'],
      experienceRequired: job?['experience_required'],
      publishedAt: DateTime.tryParse(job?['published_at']?.toString() ?? ''),
      category: job?['category'],
      skills: (job?['skills'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class LikedJobItem {
  final int jobId;
  final String jobTitle;
  final String companyName;
  final String? companyLogo;
  final String? location;
  final bool isRemote;
  final String? contractType;
  final int? salaryMin;
  final int? salaryMax;
  final String? description;
  final int? experienceRequired;
  final DateTime? publishedAt;
  final String? category;
  final List<String> skills;

  LikedJobItem({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    this.companyLogo,
    this.location,
    this.isRemote = false,
    this.contractType,
    this.salaryMin,
    this.salaryMax,
    this.description,
    this.experienceRequired,
    this.publishedAt,
    this.category,
    this.skills = const [],
  });

  factory LikedJobItem.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    return LikedJobItem(
      jobId: job?['id'] ?? 0,
      jobTitle: job?['title'] ?? '',
      companyName: job?['company']?['name'] ?? '',
      companyLogo: job?['company']?['logo'],
      location: job?['location'],
      isRemote: job?['is_remote'] ?? false,
      contractType: job?['contract_type'],
      salaryMin: job?['salary_min'],
      salaryMax: job?['salary_max'],
      description: job?['description'],
      experienceRequired: job?['experience_required'],
      publishedAt: DateTime.tryParse(job?['published_at']?.toString() ?? ''),
      category: job?['category'],
      skills: (job?['skills'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

class JobMatchSummary {
  final int matches;
  final int liked;
  final int rejected;
  final int saved;
  final int pendingSuggestions;

  JobMatchSummary({
    required this.matches,
    required this.liked,
    required this.rejected,
    this.saved = 0,
    required this.pendingSuggestions,
  });

  factory JobMatchSummary.fromJson(Map<String, dynamic> json) {
    return JobMatchSummary(
      matches: json['matches'] ?? 0,
      liked: json['liked'] ?? 0,
      rejected: json['rejected'] ?? 0,
      saved: json['saved'] ?? 0,
      pendingSuggestions: json['pending_suggestions'] ?? 0,
    );
  }
}

class JobFeedItem {
  final int id;
  final String title;
  final String companyName;
  final String? location;
  final bool isRemote;
  final String? contractType;
  final int? salaryMin;
  final int? salaryMax;
  final int score;
  final String? description;
  final int? experienceRequired;

  JobFeedItem({
    required this.id,
    required this.title,
    required this.companyName,
    this.location,
    required this.isRemote,
    this.contractType,
    this.salaryMin,
    this.salaryMax,
    required this.score,
    this.description,
    this.experienceRequired,
  });

  factory JobFeedItem.fromJson(Map<String, dynamic> json) {
    return JobFeedItem(
      id: json['id'],
      title: json['title'] ?? '',
      companyName: json['company']?['name'] ?? '',
      location: json['location'],
      isRemote: json['is_remote'] ?? false,
      contractType: json['contract_type'],
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      score: json['score'] ?? 0,
      description: json['description'],
      experienceRequired: json['experience_required'],
    );
  }
}

class JobMatchResult {
  final int id;
  final int score;
  final String jobTitle;
  final String companyName;

  JobMatchResult({
    required this.id,
    required this.score,
    required this.jobTitle,
    required this.companyName,
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    final company = job?['company'];
    final companyName = company is Map ? (company['name'] ?? '') : (company ?? '');

    return JobMatchResult(
      id: json['id'],
      score: json['score'] ?? 0,
      jobTitle: job?['title'] ?? '',
      companyName: companyName?.toString() ?? '',
    );
  }
}

class LikedJobItem {
  final int jobId;
  final String jobTitle;
  final String companyName;

  LikedJobItem({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
  });

  factory LikedJobItem.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>?;
    return LikedJobItem(
      jobId: job?['id'] ?? 0,
      jobTitle: job?['title'] ?? '',
      companyName: job?['company']?['name'] ?? '',
    );
  }
}

class JobMatchSummary {
  final int matches;
  final int liked;
  final int pendingSuggestions;

  JobMatchSummary({
    required this.matches,
    required this.liked,
    required this.pendingSuggestions,
  });

  factory JobMatchSummary.fromJson(Map<String, dynamic> json) {
    return JobMatchSummary(
      matches: json['matches'] ?? 0,
      liked: json['liked'] ?? 0,
      pendingSuggestions: json['pending_suggestions'] ?? 0,
    );
  }
}

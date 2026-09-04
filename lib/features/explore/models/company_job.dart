/// Une offre publiée par une entreprise "à découvrir" — cf.
/// CompanyDiscoveryController::show().
class CompanyJob {
  final int id;
  final String title;
  final String? location;
  final bool isRemote;
  final String? contractType;

  CompanyJob({
    required this.id,
    required this.title,
    this.location,
    this.isRemote = false,
    this.contractType,
  });

  factory CompanyJob.fromJson(Map<String, dynamic> json) {
    return CompanyJob(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      location: json['location'],
      isRemote: json['isRemote'] == true,
      contractType: json['contractType'],
    );
  }
}

/// Détail d'une entreprise "à découvrir" — cf. CompanyDiscoveryController::show().
class CompanyDetail {
  final int id;
  final String name;
  final String? logo;
  final String? industry;
  final String? address;
  final String? website;
  final String? email;
  final String? phone;
  final bool isFollowing;
  final List<CompanyJob> jobs;

  CompanyDetail({
    required this.id,
    required this.name,
    this.logo,
    this.industry,
    this.address,
    this.website,
    this.email,
    this.phone,
    this.isFollowing = false,
    this.jobs = const [],
  });

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    return CompanyDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
      industry: json['industry'],
      address: json['address'],
      website: json['website'],
      email: json['email'],
      phone: json['phone'],
      isFollowing: json['isFollowing'] == true,
      jobs: (json['jobs'] as List? ?? [])
          .map((e) => CompanyJob.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

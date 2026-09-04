/// Une entreprise dans "Entreprises à découvrir" (cf.
/// CompanyDiscoveryController côté backend).
class DiscoverableCompany {
  final int id;
  final String name;
  final String? logo;
  final String? industry;
  final int opportunitiesCount;
  final bool isFollowing;

  DiscoverableCompany({
    required this.id,
    required this.name,
    this.logo,
    this.industry,
    this.opportunitiesCount = 0,
    this.isFollowing = false,
  });

  factory DiscoverableCompany.fromJson(Map<String, dynamic> json) {
    return DiscoverableCompany(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'],
      industry: json['industry'],
      opportunitiesCount:
          int.tryParse(json['opportunitiesCount']?.toString() ?? '') ?? 0,
      isFollowing: json['isFollowing'] == true,
    );
  }

  DiscoverableCompany copyWith({bool? isFollowing}) {
    return DiscoverableCompany(
      id: id,
      name: name,
      logo: logo,
      industry: industry,
      opportunitiesCount: opportunitiesCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

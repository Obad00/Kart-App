class ProfileCompletionModel {
  String? jobTitle;
  String? company;
  String? phone;
  String? email;

  String? linkedin;
  String? instagram;
  String? github;
  String? facebook;
  String? website;

  String? theme;
  String? plan;
  dynamic branding;

  List<String> activatedFields;
  List<ExperienceModel> experiences;
  List<EducationModel> educations;

  ProfileCompletionModel({
    this.jobTitle,
    this.company,
    this.phone,
    this.email,
    this.linkedin,
    this.instagram,
    this.github,
    this.facebook,
    this.website,
    this.theme,
    this.plan,
    this.branding,
    List<String>? activatedFields,
    List<ExperienceModel>? experiences,
    List<EducationModel>? educations,
  })  : activatedFields = activatedFields ?? [],
        experiences = experiences ?? [],
        educations = educations ?? [];

  factory ProfileCompletionModel.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionModel(
      jobTitle: json['job_title'],
      company: json['company'],
      phone: json['phone'],
      email: json['email'],
      linkedin: json['linkedin'],
      instagram: json['instagram'],
      github: json['github'],
      facebook: json['facebook'],
      website: json['website'],
      theme: json['theme'],
      plan: json['plan'],
      branding: json['branding'],

      activatedFields:
          (json['activated_fields'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],

      experiences: (json['experiences'] as List?)
              ?.map((e) => ExperienceModel.fromJson(e))
              .toList() ??
          [],

      educations: (json['educations'] as List?)
              ?.map((e) => EducationModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "job_title": jobTitle,
      "company": company,
      "phone": phone,
      "email": email,
      "linkedin": linkedin,
      "instagram": instagram,
      "github": github,
      "facebook": facebook,
      "website": website,
      "activated_fields": activatedFields,
      "experiences": experiences.map((e) => e.toJson()).toList(),
      "educations": educations.map((e) => e.toJson()).toList(),
    };
  }
}

class ExperienceModel {
  String title;
  String company;
  String startDate;
  String? endDate;
  String description;

  ExperienceModel({
    required this.title,
    required this.company,
    required this.startDate,
    this.endDate,
    required this.description,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "company": company,
      "start_date": startDate,
      "end_date": endDate,
      "description": description,
    };
  }
}

class EducationModel {
  String school;
  String degree;
  String field;
  int startYear;
  int endYear;

  EducationModel({
    required this.school,
    required this.degree,
    required this.field,
    required this.startYear,
    required this.endYear,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      school: json['school'] ?? '',
      degree: json['degree'] ?? '',
      field: json['field'] ?? '',
      startYear: json['start_year'] ?? 0,
      endYear: json['end_year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "school": school,
      "degree": degree,
      "field": field,
      "start_year": startYear,
      "end_year": endYear,
    };
  }
}

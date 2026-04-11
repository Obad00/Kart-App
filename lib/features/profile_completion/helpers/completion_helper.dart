import '../model/profile_completion_model.dart';

class CompletionResult {
  final double percent;
  final List<String> missing;

  CompletionResult({required this.percent, required this.missing});
}

class CompletionHelper {
  static CompletionResult calculate(ProfileCompletionModel model) {
    final missing = <String>[];

    void check(String key, bool ok) {
      if (!ok) missing.add(key);
    }

    check("Poste", (model.jobTitle ?? '').isNotEmpty);
    check("Entreprise", (model.company ?? '').isNotEmpty);
    check("Téléphone", (model.phone ?? '').isNotEmpty);
    check("Email", (model.email ?? '').isNotEmpty);
    check("LinkedIn", (model.linkedin ?? '').isNotEmpty);
    check("Site web", (model.website ?? '').isNotEmpty);
    check("Expériences", model.experiences.isNotEmpty);
    check("Éducation", model.educations.isNotEmpty);

    final percent = ((8 - missing.length) / 8) * 100;

    return CompletionResult(percent: percent, missing: missing);
  }
}

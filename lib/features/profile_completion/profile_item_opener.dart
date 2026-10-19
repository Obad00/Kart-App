import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/providers/auth_provider.dart';
import '../onboarding/ui/profile_setup/profile_setup_page.dart';
import 'providers/candidate_skills_provider.dart';
import 'providers/profile_completion_provider.dart';
import 'ui/completion_form_page.dart';
import 'ui/skill_editor_sheet.dart';

/// Ouvre l'écran qui complète un critère du score de profil (clé venue du
/// serveur, cf. ProfileScoreService), puis recharge le score.
///
/// photo, poste, entreprise, contact : l'étape correspondante de
/// l'onboarding, seule. Bio, LinkedIn ou site, expérience, formation : la
/// section de « Modifier mes infos ». Compétences : l'éditeur de
/// compétences.
Future<void> openProfileItem(BuildContext context, String key) async {
  Future<void> sheet(Widget child) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => child,
      );
  Future<void> step(int index) =>
      Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ProfileSetupPage(singleStep: index)));

  switch (key) {
    case 'photo':
      await step(0);
    case 'job_title':
    case 'company':
      await step(1);
    case 'contact':
      await step(2);
    case 'bio':
      await sheet(const CompletionFormPage(section: 'basic'));
    case 'link':
      await sheet(const CompletionFormPage(section: 'social'));
    case 'skills':
      await sheet(const SkillEditorSheet());
    case 'experience':
      await sheet(const CompletionFormPage(section: 'experiences', addOnly: true));
    case 'education':
      await sheet(const CompletionFormPage(section: 'educations', addOnly: true));
    default:
      await sheet(const CompletionFormPage());
  }

  if (!context.mounted) return;
  // Score recalculé par le serveur après la modification.
  await Future.wait([
    context.read<AuthProvider>().loadMe(),
    context.read<ProfileCompletionProvider>().load(),
    context.read<CandidateSkillsProvider>().load(),
  ]);
}

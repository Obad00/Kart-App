import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/contacts/providers/contacts_provider.dart';
import '../../features/contacts/providers/highlight_provider.dart';
import '../../features/digital_card/providers/card_provider.dart';
import '../../features/jobmatch/providers/jobmatch_provider.dart';
import '../../features/profile_completion/providers/candidate_skills_provider.dart';
import '../../features/profile_completion/providers/profile_completion_provider.dart';

/// Déconnecte l'utilisateur ET réinitialise tous les providers qui gardent
/// des données propres à un compte en mémoire. Ces providers sont des
/// singletons créés une seule fois à la racine de l'app (MultiProvider) et
/// ne sont jamais recréés à la déconnexion — sans ce reset explicite, le
/// compte suivant connecté sur le même appareil pouvait voir, même
/// brièvement, les données du compte précédent (profil, compétences,
/// contacts...).
///
/// À utiliser à la place d'un appel direct à `AuthProvider.logout()`
/// partout où l'utilisateur se déconnecte.
Future<void> logoutAndResetSession(BuildContext context) async {
  await context.read<AuthProvider>().logout();

  if (!context.mounted) return;
  context.read<CardProvider>().reset();
  context.read<ContactsProvider>().clear();
  context.read<HighlightProvider>().reset();
  context.read<ProfileCompletionProvider>().reset();
  context.read<CandidateSkillsProvider>().reset();
  context.read<JobMatchProvider>().reset();
}

String resolveDisplayedPlan({
  required String? cardPlan,
  required String userPlan,
  required bool hasCompany,
}) {
  final normalizedCardPlan = (cardPlan ?? '').trim().toLowerCase();
  final normalizedUserPlan = userPlan.trim().toLowerCase();

  if (normalizedCardPlan.isNotEmpty && normalizedCardPlan != 'free') {
    return formatPlanName(normalizedCardPlan);
  }

  if (normalizedUserPlan.isNotEmpty && normalizedUserPlan != 'free') {
    return formatPlanName(normalizedUserPlan);
  }

  // Un utilisateur rattaché à une entreprise a un accès de niveau Pro, mais
  // le nom "Enterprise" ne doit jamais apparaître comme libellé de plan
  // (règle App Store 3.1.1 : ça ressemble à un abonnement vendu hors app).
  if (hasCompany) {
    return 'Pro';
  }

  return 'Free';
}

String formatPlanName(String plan) {
  switch (plan) {
    case 'pro':
      return 'Pro';
    case 'enterprise':
      // Ne jamais afficher "Enterprise" comme nom de plan, définitivement.
      return 'Pro';
    case 'free':
      return 'Free';
    default:
      if (plan.isEmpty) return 'Free';
      return plan[0].toUpperCase() + plan.substring(1);
  }
}

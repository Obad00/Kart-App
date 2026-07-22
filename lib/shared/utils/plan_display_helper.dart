import '../../config/feature_flags.dart';

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

  // In this project, a user linked to a company should display Enterprise.
  if (hasCompany && FeatureFlags.businessFeaturesEnabled) {
    return 'Enterprise';
  }

  return 'Free';
}

String formatPlanName(String plan) {
  switch (plan) {
    case 'pro':
      return 'Pro';
    case 'enterprise':
      return FeatureFlags.businessFeaturesEnabled ? 'Enterprise' : 'Pro';
    case 'free':
      return 'Free';
    default:
      if (plan.isEmpty) return 'Free';
      return plan[0].toUpperCase() + plan.substring(1);
  }
}

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../onboarding/providers/company_provider.dart';

/// Logo ou couleurs de l'entreprise changés : tout ce qui les affiche est
/// relu tout de suite (fiche entreprise, carte et couleurs des écrans via
/// CardProvider, compte via AuthProvider), sans sortir et revenir.
Future<void> refreshAfterBrandingChange(BuildContext context) async {
  final company = context.read<CompanyProvider>();
  final card = context.read<CardProvider>();
  final auth = context.read<AuthProvider>();
  await Future.wait([
    company.loadMyCompany(),
    card.loadCardSummary(),
    auth.loadMe(),
  ]);
}

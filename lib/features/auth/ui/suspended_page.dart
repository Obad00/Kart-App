import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/kart_tokens.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/session_reset.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../contacts/models/contact_model.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../contacts/utils/contacts_csv.dart';
import '../providers/auth_provider.dart';
import 'delete_account_dialog.dart';

/// Membre d'une entreprise dont la licence est suspendue (/me `suspended`,
/// ou 403 `account_suspended` sur n'importe quelle requête). Seules
/// restent : la lecture et l'export des contacts, la suppression du compte
/// et la déconnexion. Aucun prix, aucun paiement, aucun lien externe.
/// La carte, son lien et son QR code continuent de fonctionner côté
/// visiteurs.
class SuspendedPage extends StatefulWidget {
  const SuspendedPage(
      {super.key,
      this.share = shareContactsCsv,
      this.resetSession = resetSessionProviders});

  /// Export et remise à zéro des données de session (remplaçables dans les
  /// tests).
  final Future<void> Function(List<ContactModel>) share;
  final void Function(BuildContext) resetSession;

  static const message =
      'Votre compte est suspendu. Pour le réactiver, contactez KART.';

  @override
  State<SuspendedPage> createState() => _SuspendedPageState();
}

class _SuspendedPageState extends State<SuspendedPage> {
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<ContactsProvider>().fetchGroupedContacts();
    });
  }

  Future<void> _export(List<ContactModel> contacts) async {
    setState(() => _exporting = true);
    try {
      await widget.share(contacts);
    } catch (_) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: "Erreur d'export", subtitle: 'Réessayez dans un instant.');
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  /// Recharge /me (et les contacts) : compte réactivé → retour normal à
  /// l'app ; session expirée → connexion.
  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final contacts = context.read<ContactsProvider>();
    await auth.loadMe();
    if (!mounted) return;

    if (auth.user == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else if (!auth.isSuspended) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      await contacts.fetchGroupedContacts();
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    widget.resetSession(context);
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final contactsProvider = context.watch<ContactsProvider>();
    final contacts = contactsProvider.allContacts;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: RefreshIndicator(
            key: const Key('suspended-refresh'),
            onRefresh: _refresh,
            child: CustomScrollView(
              // Toujours défilable : glisser vers le bas marche même si tout
              // tient à l'écran.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  sliver: SliverList.list(children: [
                    Text(
                      'Compte suspendu',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: t.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      SuspendedPage.message,
                      key: const Key('suspended-message'),
                      style: TextStyle(
                          color: t.textSecondary, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Mes contacts',
                            style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary),
                          ),
                        ),
                        if (contacts.isNotEmpty)
                          Text('${contacts.length}',
                              style: TextStyle(
                                  color: t.textSecondary, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (contacts.isNotEmpty) ...[
                      AuthPrimaryButton(
                        key: const Key('suspended-export'),
                        label: 'Exporter mes contacts',
                        icon: Icons.ios_share,
                        loading: _exporting,
                        onTap: _exporting ? null : () => _export(contacts),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ]),
                ),
                if (contactsProvider.isLoading && contacts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator())),
                  )
                else if (contacts.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Text(
                        contactsProvider.error ?? 'Aucun contact.',
                        style: TextStyle(color: t.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: t.softBorder),
                      itemBuilder: (_, index) =>
                          _ContactLine(contact: contacts[index]),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  sliver: SliverList.list(children: [
                    Center(
                      child: TextButton.icon(
                        key: const Key('suspended-reload'),
                        onPressed: _refresh,
                        icon: Icon(Icons.refresh,
                            size: 18, color: t.textSecondary),
                        label: Text('Actualiser',
                            style: TextStyle(color: t.textSecondary)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        key: const Key('suspended-logout'),
                        onPressed: _logout,
                        child: Text('Se déconnecter',
                            style: TextStyle(color: t.textSecondary)),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        key: const Key('suspended-delete'),
                        onPressed: () => showDeleteAccountDialog(context),
                        child: Text('Supprimer mon compte',
                            style: TextStyle(color: Colors.red.shade400)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contact en lecture seule : nom, poste et entreprise, e-mail, téléphone.
class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.contact});

  final ContactModel contact;

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final role = [contact.job, contact.company]
        .where((v) => v != null && v.trim().isNotEmpty)
        .join(' · ');
    final reach = [contact.phone, contact.email]
        .where((v) => v != null && v.trim().isNotEmpty)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contact.fullname,
              style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(role, style: TextStyle(color: t.textSecondary, fontSize: 13)),
          ],
          if (reach.isNotEmpty) ...[
            const SizedBox(height: 2),
            SelectableText(reach,
                style: TextStyle(color: t.textSecondary, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

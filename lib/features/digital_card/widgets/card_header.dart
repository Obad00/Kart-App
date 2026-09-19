import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../../shared/utils/jobmatch_access.dart';
import '../../../shared/utils/session_reset.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class CardHeader extends StatelessWidget {
  final String initials;
  final String fullName;
  final String subtitle;
  final VoidCallback? onLeadsTap;

  const CardHeader({
    super.key,
    required this.initials,
    required this.fullName,
    required this.subtitle,
    this.onLeadsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu deroulant du profil a gauche
        _ProfileDropdownButton(
          initials: initials,
          fullName: fullName,
        ),
        // Trois traits a droite - ouvre le CRM
        _MenuLines(onTap: onLeadsTap),
      ],
    );
  }
}

class _MenuLines extends StatelessWidget {
  final VoidCallback? onTap;

  const _MenuLines({this.onTap});

  @override
  Widget build(BuildContext context) {
    // Couleur de marque de l'entreprise (comme HomeShell) plutôt qu'un gris
    // neutre : ce bouton restait le seul élément de l'en-tête de carte à
    // ignorer le branding — remonté côté produit.
    final brand = context.companyColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brand.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLine(brand, 18),
            const SizedBox(height: 4),
            _buildLine(brand, 14),
            const SizedBox(height: 4),
            _buildLine(brand, 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(Color color, double width) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _ProfileDropdownButton extends StatelessWidget {
  final String initials;
  final String fullName;

  const _ProfileDropdownButton({
    required this.initials,
    required this.fullName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Initiales/cadre aux couleurs de l'entreprise (cf. _MenuLines).
    final brand = context.companyColor;
    final avatarPath = context.watch<AuthProvider>().user?.avatar;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? (avatarPath.startsWith('http')
            ? avatarPath
            : '${ApiEndpoints.storageUrl}/$avatarPath')
        : null;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: colors.surface,
      elevation: 8,
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          value: 'profile',
          icon: Icons.person_outline,
          title: 'Mon Profil',
          subtitle: fullName,
        ),
        _buildMenuItem(
          context,
          value: 'cards',
          icon: Icons.credit_card_outlined,
          title: 'Mes Cartes',
          subtitle: 'Gerer mes cartes digitales',
        ),
        _buildMenuItem(
          context,
          value: 'settings',
          icon: Icons.settings_outlined,
          title: 'Parametres',
          subtitle: 'Preferences de l\'application',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          context,
          value: 'logout',
          icon: Icons.logout_rounded,
          title: 'Deconnexion',
          subtitle: 'Se deconnecter du compte',
          isDestructive: true,
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brand.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        // Initiales toujours présentes en dessous (pas juste en repli
        // conditionnel) : DecorationImage n'a pas de vrai retour d'échec
        // exploitable ici, donc une image qui ne se décode pas (cf.
        // EncodingError CORS sur Flutter Web tant que le fix backend n'est
        // pas déployé) plantait silencieusement en laissant juste le fond
        // vide — remonté comme un avatar "cassé", visible même une fois le
        // problème compris. CachedNetworkImage (widget, pas juste le
        // provider) par-dessus avec un errorWidget vide : les initiales
        // recouvrent l'échec au lieu de laisser paraître un carré vide.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (avatarUrl != null)
              CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
                placeholder: (_, __) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textColor = isDestructive ? Colors.red : colors.onSurface;
    final iconColor = isDestructive ? Colors.red : colors.primary;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDestructive ? Colors.red : colors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: colors.onSurface.withValues(alpha: 0.3),
            size: 18,
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    HapticFeedback.lightImpact();

    // L'onglet Profil est en position 4 si l'onglet Offres (JobMatch) est
    // visible pour ce compte (Pro), sinon en position 3.
    final showJobMatch =
        canAccessJobMatch(context.read<AuthProvider>().user?.plan);
    final profileTabIndex = showJobMatch ? 4 : 3;

    switch (value) {
      case 'profile':
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
          arguments: {'tab': profileTabIndex},
        );
        break;
      case 'cards':
        // Rester sur la page actuelle (deja sur les cartes)
        break;
      case 'settings':
        // Naviguer vers l'onglet profil pour les parametres
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (_) => false,
          arguments: {'tab': profileTabIndex},
        );
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final currentContext = context;

    final confirm = await GlassDialog.confirm(
      currentContext,
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
      confirmLabel: 'Confirmer',
      barrierDismissible: false,
    );

    if (confirm && currentContext.mounted) {
      await logoutAndResetSession(currentContext);
      if (currentContext.mounted) {
        FeedbackOverlay.showSuccess(
          currentContext,
          title: 'Déconnexion réussie',
          subtitle: 'À bientôt sur KART !',
        );
        Navigator.of(currentContext)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }
}

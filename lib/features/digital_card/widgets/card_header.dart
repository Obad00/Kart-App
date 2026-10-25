import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/kart_tokens.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/color_contrast.dart';
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/glass_menu.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../../shared/utils/jobmatch_access.dart';
import '../../../shared/utils/session_reset.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../auth/providers/auth_provider.dart';

/// En-tête de l'écran Carte : photo (menu du profil) à gauche, bouton menu
/// (CRM) à droite. Ni nom ni titre ici : le nom est déjà affiché en grand
/// sur la carte juste en dessous.
class CardHeader extends StatelessWidget {
  final String initials;
  final String fullName;
  final VoidCallback? onLeadsTap;

  const CardHeader({
    super.key,
    required this.initials,
    required this.fullName,
    this.onLeadsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Photo de profil (menu déroulant du profil) à gauche
        _ProfileDropdownButton(
          initials: initials,
          fullName: fullName,
        ),
        // Bouton menu à droite - ouvre le CRM
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
    // Compte entreprise : couleur de marque de l'entreprise (comme HomeShell).
    // Compte individuel : bouton neutre, comme les icônes des statistiques.
    final t = KartTokens.of(context);
    final brand = CompanyColorHelper.getCompanyColorOrNull(context);
    final fg = brand ?? t.textPrimary;
    final bg = brand?.withValues(alpha: 0.12) ?? t.softFill;

    return Semantics(
      button: true,
      label: 'Menu',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: brand?.withValues(alpha: 0.15) ?? t.softBorder,
              width: 1,
            ),
          ),
          child: Icon(Icons.menu_rounded, color: fg, size: 26),
        ),
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
    // Initiales/cadre aux couleurs de l'entreprise (cf. _MenuLines).
    final brand = context.companyColor;
    final avatarPath = context.watch<AuthProvider>().user?.avatar;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? (avatarPath.startsWith('http')
            ? avatarPath
            : '${ApiEndpoints.storageUrl}/$avatarPath')
        : null;

    // Menu verre (cf. GlassMenuButton) : mêmes entrées, mêmes actions.
    return GlassMenuButton<String>(
      tooltip: 'Mon compte',
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        GlassMenuItem(
          value: 'profile',
          icon: Icons.person_outline,
          title: 'Mon Profil',
          subtitle: fullName,
        ),
        const GlassMenuItem(
          value: 'cards',
          icon: Icons.credit_card_outlined,
          title: 'Mes Cartes',
          subtitle: 'Gerer mes cartes digitales',
        ),
        const GlassMenuItem(
          value: 'settings',
          icon: Icons.settings_outlined,
          title: 'Parametres',
          subtitle: 'Preferences de l\'application',
        ),
        const GlassMenuItem(
          value: 'logout',
          icon: Icons.logout_rounded,
          title: 'Deconnexion',
          subtitle: 'Se deconnecter du compte',
          destructive: true,
          dividerBefore: true,
        ),
      ],
      child: Container(
        width: 48,
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.1),
          shape: BoxShape.circle,
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
              // Le rond est l'accent à 10 % posé sur le fond de la page :
              // c'est sur ce mélange que les initiales doivent être
              // lisibles (un accent sombre en thème sombre ne l'était pas).
              child: AvatarInitials(
                initials: initials,
                accent: brand,
                background: ColorContrast.composite(
                  brand.withValues(alpha: 0.1),
                  Theme.of(context).scaffoldBackgroundColor,
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

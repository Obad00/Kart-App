import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../../shared/utils/plan_display_helper.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../../shared/widgets/theme_toggle_widget.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/logo_picker_field.dart';
import '../widgets/edit_profile_form.dart';
import '../../profile_completion/widgets/completion_banner.dart';
import '../../profile_completion/widgets/completion_sections.dart';
import '../../profile_completion/ui/completion_form_page.dart';
import '../../contacts/providers/contacts_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Masqué pour l'instant : un seul plan individuel existe (Pro), donc
  // l'écran de changement de plan n'offre aucun vrai choix. À réactiver
  // si un second plan individuel est réintroduit.
  static const bool _planChangeEnabled = false;

  bool _personalInfoExpanded = false;

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final card = context.watch<CardProvider>();

    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;
    final fullName = '${user.firstname} ${user.lastname}'.trim();

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar avec effet de blur
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            backgroundColor: colors.surface.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Mon profil',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () => _showSettings(context),
                icon: Icon(
                  Icons.settings_outlined,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Header profil
                      _buildProfileHeader(
                          colors, companyColor, fullName, user.email),

                      const CompletionBanner(),

                      const SizedBox(height: 24),

                      // Stats rapides
                      _buildQuickStats(colors, companyColor, card),

                      const SizedBox(height: 24),

                      // Informations personnelles — fusionne identité (nom,
                      // email) et infos de carte (poste, entreprise,
                      // téléphone), pour ne plus répéter l'email entre deux
                      // sections séparées.
                      _buildSection(
                        colors: colors,
                        companyColor: companyColor,
                        icon: Icons.person_outline,
                        title: 'Informations personnelles',
                        collapsible: true,
                        expanded: _personalInfoExpanded,
                        onToggle: () => setState(
                          () => _personalInfoExpanded = !_personalInfoExpanded,
                        ),
                        trailing: TextButton(
                          onPressed: () => _openForm(context, section: 'basic'),
                          style: TextButton.styleFrom(
                            foregroundColor: companyColor,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Modifier',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        children: [
                          _buildInfoRow(
                            colors,
                            icon: Icons.badge_outlined,
                            label: 'Nom complet',
                            value: fullName.isEmpty ? '-' : fullName,
                          ),
                          _buildDivider(colors),
                          _buildInfoRow(
                            colors,
                            icon: Icons.email_outlined,
                            label: 'Adresse email',
                            value: user.email,
                          ),
                          _buildDivider(colors),
                          _buildInfoRow(
                            colors,
                            icon: Icons.work_outline,
                            label: 'Poste',
                            value: card.jobTitle ?? '-',
                          ),
                          _buildDivider(colors),
                          _buildInfoRow(
                            colors,
                            icon: Icons.business_outlined,
                            label: 'Entreprise',
                            value: card.company ?? '-',
                          ),
                          _buildDivider(colors),
                          _buildInfoRow(
                            colors,
                            icon: Icons.phone_outlined,
                            label: 'Téléphone',
                            value: card.phone ?? '-',
                          ),
                          _buildDivider(colors),
                          _buildInfoRow(
                            colors,
                            icon: Icons.workspace_premium,
                            label: 'Plan',
                            value: resolveDisplayedPlan(
                              cardPlan: card.plan,
                              userPlan: user.plan,
                              hasCompany: user.hasCompany,
                            ),
                            onTap: _planChangeEnabled
                                ? () => _openPlanSelection(context)
                                : null,
                            trailing: _planChangeEnabled
                                ? TextButton(
                                    onPressed: () => _openPlanSelection(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: companyColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: companyColor.withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Changer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          if (_planChangeEnabled)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(50, 0, 16, 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Touchez Changer pour modifier votre plan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Réseaux sociaux, Expériences, Formation, Compétences
                      const CompletionSections(),

                      const SizedBox(height: 16),

                      // Entreprise (lecture seule)
                      if (user.hasCompany) ...[
                        _buildSection(
                          colors: colors,
                          companyColor: companyColor,
                          icon: Icons.business_rounded,
                          title: 'Entreprise',
                          children: [
                            _buildInfoRow(
                              colors,
                              icon: Icons.apartment_rounded,
                              label: 'Mon entreprise',
                              value: user.company?.name ?? '',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/my-company'),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: colors.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Apparence — masqué si l'entreprise impose déjà son
                      // branding (celui-ci prime toujours sur la carte,
                      // personnaliser sa propre couleur n'aurait aucun effet).
                      if (card.status == CardStatus.hasCard &&
                          !(user.hasCompany ||
                              (card.companyLogo != null &&
                                  card.companyLogo!.isNotEmpty) ||
                              (card.companyPrimaryColor != null &&
                                  card.companyPrimaryColor!.isNotEmpty))) ...[
                        _buildSection(
                          colors: colors,
                          companyColor: companyColor,
                          icon: Icons.palette_outlined,
                          title: 'Apparence',
                          children: [
                            _buildBrandingRow(colors, companyColor, card),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Actions
                      _buildActionButtons(colors, context),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      ColorScheme colors, Color companyColor, String fullName, String? email) {
    final card = context.watch<CardProvider>();
    final hasCard = card.status == CardStatus.hasCard;
    final avatarPath = context.watch<AuthProvider>().user?.avatar;
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? (avatarPath.startsWith('http')
            ? avatarPath
            : '${ApiEndpoints.storageUrl}/$avatarPath')
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            companyColor.withValues(alpha: 0.12),
            companyColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: companyColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar avec badge de statut + édition de la photo
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            companyColor,
                            companyColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.surface,
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                _initials(fullName),
                                style: TextStyle(
                                  color: companyColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: companyColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Infos utilisateur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Utilisateur' : fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    if (hasCard &&
                        card.jobTitle != null &&
                        card.jobTitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.jobTitle!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: companyColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (hasCard &&
                        card.company != null &&
                        card.company!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.company!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email ?? '',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton editer
              IconButton(
                onPressed: () => _openEditProfileForm(context),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: companyColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
      ColorScheme colors, Color companyColor, CardProvider card) {
    final contactsProvider = context.watch<ContactsProvider>();
    final totalContacts = contactsProvider.groups.fold<int>(
      0,
      (sum, group) => sum + group.contacts.length,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            colors,
            companyColor,
            icon: Icons.qr_code_scanner,
            value: '${card.scanCount ?? 0}',
            label: 'Scans',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            colors,
            companyColor,
            icon: Icons.people_outline,
            value: '$totalContacts',
            label: 'Contacts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            colors,
            companyColor,
            icon: Icons.share_outlined,
            value: '${card.shareCount ?? 0}',
            label: 'Partages',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ColorScheme colors,
    Color companyColor, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: companyColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required ColorScheme colors,
    required Color companyColor,
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool collapsible = false,
    bool expanded = true,
    VoidCallback? onToggle,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: companyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: companyColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                  if (collapsible)
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                ],
              ),
            ),
          ),

          // Contenu
          if (!collapsible || expanded) ...[
            ...children,
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: colors.onSurface.withValues(alpha: 0.06),
      ),
    );
  }

  Widget _buildBrandingRow(
      ColorScheme colors, Color companyColor, CardProvider card) {
    final accentColor = _parseHexColor(card.accentColor) ?? companyColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.onSurface.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personnalisation de la carte',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  card.accentColor != null || card.logo != null
                      ? 'Couleur et logo personnalisés'
                      : 'Aucune personnalisation',
                  style: TextStyle(
                    fontSize: 15,
                    color: colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openBrandingEditor(context),
            style: TextButton.styleFrom(
              foregroundColor: companyColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: companyColor.withValues(alpha: 0.2)),
              ),
            ),
            child: const Text(
              'Personnaliser',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons(ColorScheme colors, BuildContext context) {
    return Column(
      children: [
        // Toggle Mode Light/Dark
        const ThemeToggleWidget(),

        const SizedBox(height: 16),

        // Bouton Déconnexion
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Version de l'app
        Text(
          _appVersion.isNotEmpty ? 'KART v$_appVersion' : 'KART',
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurface.withValues(alpha: 0.3),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  void _openEditProfileForm(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const EditProfileForm(),
      ),
    );
  }

  void _openPlanSelection(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed('/plans');
  }

  void _openForm(BuildContext context, {String? section}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompletionFormPage(section: section),
    );
  }

  void _showSettings(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Titre
              Text(
                'Paramètres',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              // Section Apparence
              Text(
                'APPARENCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Toggle de thème
              const ThemeToggleWidget(),

              const SizedBox(height: 24),

              // Section Compte
              Text(
                'COMPTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Options de compte
              _buildSettingsItem(
                context,
                icon: Icons.lock_outline,
                title: 'Changer le mot de passe',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/change-password');
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  // Navigation vers paramètres notifications
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Confidentialité',
                onTap: () async {
                  final url = Uri.parse('https://kart.business/privacy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),

              const SizedBox(height: 14),

              _buildDangerSettingsItem(
                context,
                icon: Icons.delete_forever_outlined,
                title: 'Supprimer le compte',
                subtitle: 'Cette action est irréversible',
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountDialog(context);
                },
              ),

              const SizedBox(height: 24),

              // Section Support
              Text(
                'SUPPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              _buildSettingsItem(
                context,
                icon: Icons.travel_explore_rounded,
                title: 'Revoir le tutoriel',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (_) => false,
                    arguments: {'tab': 0, 'replayTour': true},
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                context,
                icon: Icons.help_outline,
                title: 'Centre d\'aide',
                onTap: () async {
                  final url = Uri.parse('https://kart.business/support');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildSettingsItem(
                context,
                icon: Icons.info_outline,
                title: 'À propos de Kart',
                subtitle: _appVersion.isNotEmpty ? 'Version $_appVersion' : '',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('KART'),
                      content: Text(
                        _appVersion.isNotEmpty
                            ? 'Version $_appVersion\nVotre carte de visite digitale.\n\n© ${DateTime.now().year} KART. Tous droits réservés.'
                            : 'Votre carte de visite digitale.\n\n© ${DateTime.now().year} KART. Tous droits réservés.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.red.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final pageContext = this.context;
    bool isLoading = false;
    String? passwordError;
    bool obscurePassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> handleDelete() async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                setStateDialog(() {
                  passwordError = 'Entrez votre mot de passe';
                });
                return;
              }

              setStateDialog(() {
                isLoading = true;
                passwordError = null;
              });

              final auth = pageContext.read<AuthProvider>();
              final result = await auth.deleteAccount(password);

              if (!dialogContext.mounted) return;

              if (result.status == DeleteAccountStatus.success) {
                Navigator.of(dialogContext).pop();
                if (!mounted || !pageContext.mounted) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(
                    content: Text('Votre compte a été supprimé avec succès'),
                  ),
                );
                Navigator.of(pageContext)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
                return;
              }

              if (result.status == DeleteAccountStatus.invalidPassword) {
                setStateDialog(() {
                  isLoading = false;
                  passwordError = result.message ?? 'Mot de passe incorrect';
                });
                return;
              }

              if (result.status == DeleteAccountStatus.sessionExpired) {
                Navigator.of(dialogContext).pop();
                if (!mounted || !pageContext.mounted) return;
                ScaffoldMessenger.of(pageContext).showSnackBar(
                  const SnackBar(
                    content: Text('Session expirée'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(pageContext)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
                return;
              }

              setStateDialog(() {
                isLoading = false;
              });
              if (!mounted || !pageContext.mounted) return;
              ScaffoldMessenger.of(pageContext).showSnackBar(
                const SnackBar(
                  content: Text('Une erreur est survenue. Veuillez réessayer.'),
                  backgroundColor: Colors.red,
                ),
              );
            }

            final colors = Theme.of(context).colorScheme;

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Supprimer le compte',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Cette action est irréversible. Toutes vos données seront supprimées.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: colors.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        hintText: 'Entrez votre mot de passe',
                        errorText: passwordError,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setStateDialog(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.onSurface.withValues(alpha: 0.15),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.3,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : handleDelete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Confirmer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      passwordController.dispose();
    });
  }

  void _showLogoutDialog(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final currentContext = context;

    final confirm = await showDialog<bool>(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && currentContext.mounted) {
      await context.read<AuthProvider>().logout();
      if (currentContext.mounted) {
        Navigator.of(currentContext)
            .pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  void _openBrandingEditor(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _BrandingEditor(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authProvider.updateAvatar(picked.path);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

// ================= THEME PICKER =================

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  try {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
  } catch (_) {}
  return null;
}

String _colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
}

// ================= BRANDING EDITOR =================
// Personnalisation gratuite de la carte : couleur d'accent + logo/photo.
// Aucune restriction de plan (contrairement à l'ancien sélecteur de thème).

class _BrandingEditor extends StatefulWidget {
  const _BrandingEditor();

  @override
  State<_BrandingEditor> createState() => _BrandingEditorState();
}

class _BrandingEditorState extends State<_BrandingEditor> {
  late Color _accentColor;
  String? _newLogoPath;
  bool _logoRemoved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final card = context.read<CardProvider>();
    _accentColor = _parseHexColor(card.accentColor) ?? const Color(0xFF2563EB);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<CardProvider>().updatePersonalBranding(
            accentColorHex: _colorToHex(_accentColor),
            localLogoPath: _newLogoPath,
            removeLogo: _logoRemoved,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardProvider>();
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Personnaliser ma carte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ColorPickerField(
              label: 'Couleur d\'accent',
              initialColor: _accentColor,
              onColorChanged: (color) => setState(() => _accentColor = color),
            ),
            const SizedBox(height: 20),

            LogoPickerField(
              label: 'Logo ou photo',
              title: 'Logo personnel',
              initialUrl: card.logo,
              onLogoChanged: (path) {
                setState(() {
                  if (path == null) {
                    _logoRemoved = true;
                    _newLogoPath = null;
                  } else {
                    _logoRemoved = false;
                    _newLogoPath = path;
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

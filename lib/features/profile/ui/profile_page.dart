import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../../shared/utils/plan_display_helper.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../digital_card/exceptions/theme_forbidden_exception.dart';
import '../../../shared/widgets/theme_toggle_widget.dart';
import '../widgets/edit_profile_form.dart';
import '../../digital_card/ui/create_card_page.dart';
import '../../profile_completion/widgets/completion_banner.dart';
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

                      // Informations personnelles
                      _buildSection(
                        colors: colors,
                        companyColor: companyColor,
                        icon: Icons.person_outline,
                        title: 'Informations personnelles',
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Carte digitale
                      _buildSection(
                        colors: colors,
                        companyColor: companyColor,
                        icon: Icons.credit_card_outlined,
                        title: 'Carte digitale',
                        children: card.status == CardStatus.hasCard
                            ? [
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
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: card.email ?? '-',
                                ),
                                _buildDivider(colors),

                                _buildUrlRow(
                                  colors,
                                  label: 'LinkedIn',
                                  url: card.linkedin,
                                  icon: Icons.work_outline,
                                  color: const Color(0xFF0A66C2),
                                ),
                                _buildDivider(colors),

                                _buildUrlRow(
                                  colors,
                                  label: 'Site web',
                                  url: card.website,
                                  icon: Icons.language,
                                ),
                                _buildDivider(colors),

                                _buildUrlRow(
                                  colors,
                                  label: 'GitHub',
                                  url: card.github,
                                  icon: Icons.code,
                                ),
                                _buildDivider(colors),

                                _buildUrlRow(
                                  colors,
                                  label: 'Instagram',
                                  url: card.instagram,
                                  icon: Icons.camera_alt_outlined,
                                  color: const Color(0xFFE1306C),
                                ),
                                _buildDivider(colors),

                                _buildUrlRow(
                                  colors,
                                  label: 'Facebook',
                                  url: card.facebook,
                                  icon: Icons.facebook,
                                  color: const Color(0xFF1877F2),
                                ),
                                _buildDivider(colors),

                                const SizedBox(height: 10),

                                // EXPERIENCES
                                _buildInfoRow(
                                  colors,
                                  icon: Icons.history,
                                  label: 'Expérience',
                                  value: card.experiences.isNotEmpty
                                      ? '${card.experiences.first['title']} chez ${card.experiences.first['company']}'
                                      : '-',
                                  onTap: card.experiences.isNotEmpty
                                      ? () => _openExperiencesSheet(
                                          context, card.experiences)
                                      : null,
                                ),

                                // EDUCATION
                                _buildInfoRow(
                                  colors,
                                  icon: Icons.school_outlined,
                                  label: 'Formation',
                                  value: card.educations.isNotEmpty
                                      ? '${card.educations.first['degree']} - ${card.educations.first['school']}'
                                      : '-',
                                  onTap: card.educations.isNotEmpty
                                      ? () => _openEducationSheet(
                                          context, card.educations)
                                      : null,
                                ),

                                // PLAN
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
                                  onTap: () => _openPlanSelection(context),
                                  trailing: TextButton(
                                    onPressed: () =>
                                        _openPlanSelection(context),
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
                                          color: companyColor.withValues(
                                              alpha: 0.25),
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
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(50, 0, 16, 6),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Touchez Changer pour modifier votre plan.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colors.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ]
                            : [
                                _buildEmptyCardState(colors, companyColor),
                              ],
                      ),

                      const SizedBox(height: 16),

                      // Apparence
                      if (card.status == CardStatus.hasCard) ...[
                        _buildSection(
                          colors: colors,
                          companyColor: companyColor,
                          icon: Icons.palette_outlined,
                          title: 'Apparence',
                          children: [
                            _buildThemeSelector(colors, companyColor, card),
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

  void _openExperiencesSheet(
    BuildContext context,
    List experiences,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Expériences",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...experiences.map((exp) {
                return ListTile(
                  leading: const Icon(Icons.work_outline),
                  title: Text(exp['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exp['company'] ?? ''),
                      Text(
                        "${exp['start_date']} → ${exp['end_date'] ?? 'Présent'}",
                      ),
                      if (exp['description'] != null) Text(exp['description']),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _openEducationSheet(
    BuildContext context,
    List educations,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Formations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...educations.map((edu) {
                return ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(edu['degree'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(edu['school'] ?? ''),
                      Text("${edu['start_year']} → ${edu['end_year']}"),
                      if (edu['field'] != null) Text(edu['field']),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      ColorScheme colors, Color companyColor, String fullName, String? email) {
    final card = context.watch<CardProvider>();
    final hasCard = card.status == CardStatus.hasCard;

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
              // Avatar avec badge de statut
              Stack(
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
                      child: Text(
                        _initials(fullName),
                        style: TextStyle(
                          color: companyColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
          Padding(
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          ...children,

          const SizedBox(height: 8),
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

  Widget _buildUrlRow(
    ColorScheme colors, {
    required String? url,
    required String label,
    required IconData icon,
    Color? color,
  }) {
    final trimmedUrl = url?.trim();
    final hasUrl = trimmedUrl != null && trimmedUrl.isNotEmpty;

    final parsedUri = hasUrl ? Uri.tryParse(trimmedUrl) : null;

    return _buildInfoRow(
      colors,
      icon: icon,
      label: label,
      value: hasUrl ? trimmedUrl : '-',
      onTap: (hasUrl && parsedUri != null)
          ? () async {
              HapticFeedback.lightImpact();

              if (await canLaunchUrl(parsedUri)) {
                await launchUrl(
                  parsedUri,
                  mode: LaunchMode.externalApplication,
                );
              }
            }
          : null,
      trailing: hasUrl
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (color ?? colors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.open_in_new,
                size: 14,
                color: color ?? colors.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyCardState(ColorScheme colors, Color companyColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: companyColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_off_outlined,
              size: 32,
              color: companyColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune carte digitale',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Créez votre carte pour afficher vos informations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final cardProvider = context.read<CardProvider>();

              final created = await navigator.push(
                MaterialPageRoute(
                  builder: (_) => const CreateCardPage(),
                ),
              );

              if (created == true) {
                await cardProvider.loadCardSummary();
                await cardProvider.loadMyCardQr();
              }
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Créer ma carte'),
            style: TextButton.styleFrom(
              foregroundColor: companyColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: companyColor.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(
      ColorScheme colors, Color companyColor, CardProvider card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.color_lens_outlined,
            size: 20,
            color: colors.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thème de la carte',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _themeLabel(card.theme),
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
            onPressed: () => _openThemePicker(context),
            style: TextButton.styleFrom(
              foregroundColor: companyColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: companyColor.withValues(alpha: 0.2)),
              ),
            ),
            child: const Text(
              'Changer',
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
          'KART v1.0.0',
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
                  // Navigation vers changement de mot de passe
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
                onTap: () {
                  Navigator.pop(context);
                  // Navigation vers paramètres confidentialité
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
                icon: Icons.help_outline,
                title: 'Centre d\'aide',
                onTap: () async {
                  final url = Uri.parse('https://kart.sn/help');
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
                subtitle: 'Version 1.0.0',
                onTap: () {
                  Navigator.pop(context);
                  // Afficher infos app
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

  void _openThemePicker(BuildContext context) {
    final parentContext = context;
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ThemePicker(parentContext: parentContext),
    );
  }

  String _themeLabel(String? theme) {
    switch (theme) {
      case 'dark_minimal':
        return 'Dark minimal';
      case 'clean_light':
        return 'Clean light';
      default:
        return 'Classique';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

// ================= THEME PICKER =================

class _ThemePicker extends StatelessWidget {
  final BuildContext parentContext;

  const _ThemePicker({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardProvider>();
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;

    // Vérifier si l'utilisateur est premium ou entreprise
    final bool isPremiumOrCompany = auth.user?.isPro == true ||
        auth.user?.hasCompany == true ||
        (card.companyPrimaryColor != null &&
            card.companyPrimaryColor!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
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
                'Thème de la carte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _themeItem(context, card, colors, 'default', 'Classique',
              Icons.light_mode_outlined,
              isPremium: false, isPremiumOrCompany: isPremiumOrCompany),
          const SizedBox(height: 10),
          _themeItem(context, card, colors, 'clean_light', 'Clean light',
              Icons.wb_sunny_outlined,
              isPremium: true, isPremiumOrCompany: isPremiumOrCompany),
          const SizedBox(height: 10),
          _themeItem(context, card, colors, 'dark_minimal', 'Dark minimal',
              Icons.dark_mode_outlined,
              isPremium: true, isPremiumOrCompany: isPremiumOrCompany),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _themeItem(
    BuildContext context,
    CardProvider card,
    ColorScheme colors,
    String value,
    String label,
    IconData icon, {
    required bool isPremium,
    required bool isPremiumOrCompany,
  }) {
    final selected = card.theme == value;
    final bool isLocked = isPremium && !isPremiumOrCompany;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked
            ? () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                _showProDialog(parentContext,
                    'Ce thème est réservé aux comptes Premium et Entreprise');
              }
            : () async {
                HapticFeedback.lightImpact();
                try {
                  await card.updateTheme(value);
                  if (context.mounted) Navigator.pop(context);
                } on ThemeForbiddenException catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    _showProDialog(parentContext, e.message);
                  }
                }
              },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.1)
                : isLocked
                    ? colors.onSurface.withValues(alpha: 0.02)
                    : colors.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.3)
                  : colors.onSurface.withValues(alpha: 0.06),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isLocked
                    ? colors.onSurface.withValues(alpha: 0.3)
                    : selected
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: isLocked
                        ? colors.onSurface.withValues(alpha: 0.4)
                        : colors.onSurface,
                  ),
                ),
              ),
              if (isLocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Fonction premium'),
          ],
        ),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Plus tard'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context, rootNavigator: true)
                        .pushNamed('/plans');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Passer PRO'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../../shared/widgets/theme_toggle_widget.dart';
import '../../../shared/widgets/color_picker_field.dart';
import '../../../shared/widgets/logo_picker_field.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../../../shared/tour/tour_prefs.dart';
import '../../../shared/utils/session_reset.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers/professional_document_provider.dart';
import '../widgets/document_row.dart';
import '../widgets/document_upload_sheet.dart';
import '../../profile_completion/helpers/completion_helper.dart';
import '../../profile_completion/widgets/completion_banner.dart';
import '../../profile_completion/widgets/completion_sections.dart';
import '../../profile_completion/ui/completion_form_page.dart';
import '../../profile_completion/providers/profile_completion_provider.dart';
import '../../profile_completion/providers/candidate_skills_provider.dart';
import 'notification_settings_page.dart';

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

  String _appVersion = '';

  final _avatarTourKey = GlobalKey();
  final _settingsTourKey = GlobalKey();

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

    // Recharge la complétion et les compétences à chaque entrée sur cet
    // onglet — sans ça, ces providers ne se rafraîchissent jamais tout
    // seuls après une modification faite ailleurs (ex: formulaire
    // "Informations personnelles"), donnant l'impression que la
    // complétion "met du temps à se mettre à jour".
    context.read<ProfileCompletionProvider>().load();
    context.read<CandidateSkillsProvider>().load();

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  Future<void> _maybeStartTour() async {
    if (!mounted || await TourPrefs.hasSeen('profile')) return;

    await TourPrefs.markSeen('profile');
    if (!mounted) return;

    ShowCaseWidget.of(context).startShowCase(
      [_avatarTourKey, _settingsTourKey],
    );
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
      return const Center(child: CircularProgressIndicator());
    }

    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;
    final fullName = '${user.firstname} ${user.lastname}'.trim();

    // Pas de Scaffold ici : HomeShell en possède déjà un pour toute la
    // navigation (fond colorScheme.surface unique). Cette page n'utilise
    // qu'un SliverAppBar (dans ce CustomScrollView), pas un vrai
    // Scaffold.appBar — rien ne justifiait un Scaffold supplémentaire.
    return CustomScrollView(
      slivers: [
        // App Bar avec effet de blur — verre dépoli façon Apple : le
        // contenu défile réellement derrière (pinned + floating), le
        // BackdropFilter a donc quelque chose à flouter au scroll.
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.32
                        : 0.5,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: colors.onSurface.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Mon profil',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            Showcase(
              key: _settingsTourKey,
              title: 'Réglages',
              description:
                  'Retrouvez vos préférences, le centre d\'aide et les guides ici.',
              targetShapeBorder: const CircleBorder(),
              child: IconButton(
                onPressed: () => _showSettings(context),
                icon: Icon(
                  Icons.settings_outlined,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
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

                    const SizedBox(height: 16),

                    // Documents professionnels — diplômes, attestations,
                    // certificats ; juste après l'en-tête comme demandé.
                    // Vérification réservée au superadmin (CRM web).
                    _buildDocumentsSection(colors, companyColor),

                    const CompletionBanner(),

                    const SizedBox(height: 16),

                    // Expériences, Formation, Compétences, Centres
                    // d'intérêt, Réseaux sociaux — "Informations
                    // personnelles" (nom/email/poste/entreprise/téléphone)
                    // supprimée : ces infos sont déjà toutes visibles dans
                    // l'en-tête ci-dessus (bouton "Modifier"), les répéter
                    // ici faisait doublon.
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

                    // 40 de respiration + la pilule de nav flottante de
                    // HomeShell (extendBody : la safe area seule ne
                    // suffit plus à protéger le dernier élément).
                    const SizedBox(
                        height: 40 + BottomNavMetrics.reservedHeight),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Carte d'en-tête du profil — reprend la maquette fournie (avatar, nom,
  // bio, statistiques Expérience/Compétences/Kart Score, actions
  // Partager/Modifier) avec les couleurs de l'app (companyColor) plutôt que
  // le thème sombre/doré de la référence. Remplace l'ancien en-tête + la
  // rangée "Stats rapides" (Scans/Contacts/Partages), désormais fusionnés
  // en une seule section comme sur l'image.
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

    final completionModel = context.watch<ProfileCompletionProvider>().model;
    final skillsCount = context.watch<CandidateSkillsProvider>().skills.length;
    final kartScore = CompletionHelper.calculate(
      completionModel,
      hasSkills: skillsCount > 0,
    ).percent.round().clamp(0, 100);
    final experienceYears = _computeExperienceYears(card.experiences);
    // Badge "vérifié" = profil 100% complet plutôt qu'une notion de
    // vérification qui n'existe pas côté backend — évite d'afficher un
    // statut qu'on ne peut pas garantir.
    final isComplete = kartScore >= 100;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar : tap = voir en grand (comme les applis modernes),
              // badge caméra séparé = changer la photo.
              Showcase(
                key: _avatarTourKey,
                title: 'Votre photo',
                description:
                    'Appuyez pour l\'agrandir, ou sur l\'icône appareil photo pour la changer.',
                targetShapeBorder: const CircleBorder(),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: avatarUrl == null
                          ? _pickAndUploadAvatar
                          : () => PhotoViewer.show(context, avatarUrl),
                      child: Container(
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
                        child: Hero(
                          tag: avatarUrl ?? 'profile-avatar-placeholder',
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: colors.surface,
                            backgroundImage: avatarUrl != null
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
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
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showAvatarOptions(avatarUrl != null),
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName.isEmpty ? 'Utilisateur' : fullName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isComplete) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: companyColor,
                          ),
                        ],
                      ],
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
                    // Indenté, aligné avec le nom/poste/entreprise (pas
                    // avec la photo) — cf. maquette fournie.
                    if (hasCard &&
                        card.bio != null &&
                        card.bio!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ExpandableText(
                        card.bio!,
                        maxLines: 3,
                        accentColor: companyColor,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: colors.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildProfileStat(
                    colors,
                    companyColor,
                    icon: Icons.work_outline_rounded,
                    label: 'Expérience',
                    value: experienceYears > 0
                        ? '$experienceYears an${experienceYears > 1 ? 's' : ''}'
                        : '—',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 2,
                  endIndent: 2,
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _buildProfileStat(
                    colors,
                    companyColor,
                    icon: Icons.star_outline_rounded,
                    label: 'Compétences',
                    // Juste le nombre — le libellé "Compétences" au-dessus
                    // dit déjà de quoi il s'agit, pas besoin de le répéter
                    // dans la valeur (cf. "23" plutôt que "23 compétences").
                    value: skillsCount > 0 ? '$skillsCount' : '—',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 2,
                  endIndent: 2,
                  color: colors.onSurface.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: _buildProfileStat(
                    colors,
                    companyColor,
                    icon: Icons.shield_outlined,
                    label: 'Kart score',
                    value: '$kartScore/100',
                    caption: _kartScoreCaption(kartScore),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _shareProfile(context),
                  icon: const Icon(Icons.ios_share_rounded, size: 17),
                  label: const Text('Partager mon profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: companyColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    // fontFamily explicite : ElevatedButton.styleFrom(textStyle: ...)
                    // remplace entièrement le DefaultTextStyle ambiant (celui du thème,
                    // en Syne) au lieu de le compléter — sans ce fontFamily, ce label
                    // retombait sur la police système et jurait avec le reste de la
                    // page (nom, titres...), tous en Syne.
                    textStyle: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _openForm(context, section: 'basic'),
                  icon:
                      Icon(Icons.edit_outlined, size: 17, color: companyColor),
                  label: Text('Modifier',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: companyColor)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: companyColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(
    ColorScheme colors,
    Color companyColor, {
    required IconData icon,
    required String label,
    required String value,
    String? caption,
  }) {
    // Padding horizontal : sans lui, le texte de chaque stat (aligné à
    // gauche) touchait directement la ligne verticale de séparation —
    // pas normal, décalage nécessaire des deux côtés.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: companyColor),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              // 8 plutôt que 9.5, letterSpacing resserré : "COMPÉTENCES"
              // tient maintenant sur une ligne sans être tronqué, plutôt
              // que de compter sur l'ellipsis (maxLines ci-dessous) qui
              // coupait le mot sur les colonnes étroites.
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: colors.onSurface.withValues(alpha: 0.45),
            ),
            // Sur les écrans étroits (iPhone mini/SE), 3 colonnes dans la
            // largeur de carte ne laissent qu'une soixantaine de pixels par
            // stat — sans limite, un libellé comme "COMPÉTENCES" pouvait
            // passer à la ligne et désaligner la rangée entière.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: companyColor,
              ),
              // "Profil très complet" est le plus long des libellés
              // possibles (cf. _kartScoreCaption) — 2 lignes plutôt qu'un
              // débordement non borné sur les colonnes étroites.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Légende du Kart Score — mêmes seuils que la barre de progression du
  /// [CompletionBanner] (100% = carte "complète").
  String _kartScoreCaption(int score) {
    if (score >= 90) return 'Profil très complet';
    if (score >= 70) return 'Profil complet';
    if (score >= 40) return 'Profil à compléter';
    return 'Profil incomplet';
  }

  /// Somme les durées des expériences (start_date → end_date, ou
  /// aujourd'hui si toujours en cours), arrondie à l'année — calculé à
  /// partir des vraies dates saisies dans "Expériences", pas une valeur
  /// arbitraire.
  int _computeExperienceYears(List<dynamic> experiences) {
    double totalDays = 0;
    for (final exp in experiences) {
      if (exp is! Map) continue;
      final start = DateTime.tryParse(exp['start_date']?.toString() ?? '');
      if (start == null) continue;
      final end = DateTime.tryParse(exp['end_date']?.toString() ?? '') ??
          DateTime.now();
      if (end.isAfter(start)) {
        totalDays += end.difference(start).inDays;
      }
    }
    return (totalDays / 365).round();
  }

  /// Ouvre le partage natif avec le lien de la carte publique — même
  /// logique que le bouton de partage de MyDigitalCardPage.
  Future<void> _shareProfile(BuildContext context) async {
    HapticFeedback.lightImpact();
    final cardProvider = context.read<CardProvider>();
    final authProvider = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if ((cardProvider.shareUrl == null || cardProvider.shareUrl!.isEmpty) &&
          (cardProvider.slug == null || cardProvider.slug!.isEmpty)) {
        await cardProvider.loadCardSummary();
      }
      if (!mounted) return;

      String? url = cardProvider.shareUrl;
      if ((url == null || url.isEmpty) &&
          cardProvider.slug != null &&
          cardProvider.slug!.isNotEmpty) {
        url = 'https://kart.business/card/${cardProvider.slug}';
      }
      if (url == null || url.isEmpty) {
        throw Exception('Créez votre carte pour pouvoir la partager.');
      }

      final user = authProvider.user;
      final fullName = user != null
          ? '${user.firstname} ${user.lastname}'.trim()
          : 'Utilisateur';
      final buffer = StringBuffer()
        ..write('Bonjour ! Voici ma carte de visite digitale.');
      if (cardProvider.jobTitle != null || cardProvider.company != null) {
        buffer.write('\n\n$fullName');
        if (cardProvider.jobTitle != null) {
          buffer.write(' - ${cardProvider.jobTitle}');
        }
        if (cardProvider.company != null) {
          buffer.write(' @ ${cardProvider.company}');
        }
      }
      buffer.write('\n\n$url');

      await SharePlus.instance.share(ShareParams(text: buffer.toString()));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// "Documents professionnels" — diplômes, attestations, certificats.
  /// Réutilise [_buildSection] pour garder le même chrome (icône + titre +
  /// action "Ajouter") que les autres sections de la page. Le badge
  /// "Vérifié" affiché par [DocumentRow] reflète uniquement l'action du
  /// superadmin côté CRM web — jamais posé par l'utilisateur lui-même.
  Widget _buildDocumentsSection(ColorScheme colors, Color companyColor) {
    final provider = context.watch<ProfessionalDocumentProvider>();

    return _buildSection(
      colors: colors,
      companyColor: companyColor,
      icon: Icons.workspace_premium_outlined,
      title: 'Documents professionnels',
      trailing: TextButton(
        onPressed: () => _openDocumentUploadSheet(context, companyColor),
        style: TextButton.styleFrom(
          foregroundColor: companyColor,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          'Ajouter',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      children: [
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.documents.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Text(
              'Ajoutez vos diplômes, attestations ou certificats pour renforcer votre profil.',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Column(
              children: provider.documents
                  .map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DocumentRow(
                          document: doc,
                          companyColor: companyColor,
                          onDelete: () => provider.remove(doc.id),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _openDocumentUploadSheet(BuildContext context, Color companyColor) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DocumentUploadSheet(companyColor: companyColor),
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
    // Plus de carte (fond + bordure) autour des sections : juste l'en-tête
    // (icône + titre) et le contenu, séparés par l'espacement entre
    // sections dans ProfilePage.build() — les informations "respirent"
    // plutôt que d'être chacune enfermée dans un encart.
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de section
          InkWell(
            onTap: collapsible ? onToggle : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
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
          // horizontal: 0 — plus de carte autour de la section, ce contenu
          // s'aligne maintenant avec l'icône de l'en-tête au lieu d'avoir
          // son propre retrait pensé pour l'ancien encart.
          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildBrandingRow(
      ColorScheme colors, Color companyColor, CardProvider card) {
    final accentColor = _parseHexColor(card.accentColor) ?? companyColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSettingsPage()),
                  );
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
                title: 'Revoir les guides',
                onTap: () async {
                  // Réinitialise tous les guides (barre de navigation +
                  // chaque écran), pas seulement celui de la barre — ils se
                  // redéclenchent alors au fil de la navigation, comme au
                  // tout premier lancement.
                  await TourPrefs.resetAll();
                  if (!context.mounted) return;
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
                icon: Icons.system_update_alt_rounded,
                title: 'Mettre à jour l\'app',
                onTap: () async {
                  // Platform.isIOS n'existe pas sur web (kIsWeb) : ce réglage
                  // ne s'affiche de toute façon que dans l'app installée,
                  // mais on reste défensif au cas où ce widget serait un jour
                  // atteint depuis un build web.
                  final url = Uri.parse((!kIsWeb && Platform.isIOS)
                      ? 'https://apps.apple.com/sn/app/kart/id6778524832?l=fr-FR'
                      : 'https://play.google.com/store/apps/details?id=com.kartapp.app');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
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
                // deleteAccount() appelle déjà logout() en interne, mais pas
                // le reset des autres providers (cf. session_reset.dart) —
                // sans ça, un compte connecté juste après sur le même
                // appareil verrait les données de celui qui vient d'être
                // supprimé.
                resetSessionProviders(pageContext);
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
      await logoutAndResetSession(currentContext);
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

  void _showAvatarOptions(bool hasAvatar) {
    HapticFeedback.lightImpact();
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: colors.onSurface),
                title: const Text('Changer la photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndUploadAvatar();
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red),
                  title: const Text('Supprimer la photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la photo ?'),
        content:
            const Text('Votre photo de profil sera retirée de votre carte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await authProvider.deleteAvatar();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
      final bytes = await picked.readAsBytes();
      await authProvider.updateAvatar(bytes, picked.name);
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
                Expanded(
                  child: Text(
                    'Personnaliser ma carte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

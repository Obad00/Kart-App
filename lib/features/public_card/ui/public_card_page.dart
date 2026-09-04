import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/utils/company_color_helper.dart'
    show readableForegroundOn;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../data/public_card_service.dart';
import '../../../shared/services/card_service.dart';
import '../widgets/lead_capture_sheet.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/skill_chip.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../contacts/providers/highlight_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/models/explore_user.dart';
import '../../explore/widgets/connect_action_button.dart';
import '../../../shared/widgets/expandable_text.dart';

// Même bleu (indigo) que CompletionSections._interestsAccentColor côté
// profil — cohérence entre l'affichage lecture seule ici et l'éditeur.
const _interestsAccentColor = Color(0xFF6366F1);

class PublicCardPage extends StatefulWidget {
  final String slug;

  /// Renseigné uniquement quand cette page affiche un contact déjà
  /// enregistré (ouverte depuis la liste des contacts) — permet de proposer
  /// des actions propres à un contact (ex: le déplacer vers un highlight).
  /// Reste `null` pour une carte publique consultée par un visiteur.
  final int? contactId;

  const PublicCardPage({super.key, required this.slug, this.contactId});

  @override
  State<PublicCardPage> createState() => _PublicCardPageState();
}

class _PublicCardPageState extends State<PublicCardPage>
    with TickerProviderStateMixin {
  final _service = PublicCardService();
  Map<String, dynamic>? card;
  bool isLoading = true;

  // Vrai si ce profil est déjà un contact — soit parce que la page a été
  // ouverte depuis la liste des contacts (widget.contactId), soit parce
  // que le backend nous dit qu'un contact mutuel existe déjà (demande de
  // mise en relation acceptée) même en arrivant ici via un lien/QR direct.
  // Sans ce second cas, la page reste bloquée sur "Se connecter" à chaque
  // réouverture après acceptation, même si le contact a bien été créé.
  bool get _isConnected =>
      widget.contactId != null || card?['connection_status'] == 'contact';

  Color get _accentColor =>
      _parseHexColor(card?['accent_color'] as String?) ??
      const Color(0xFF2563EB);

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

  // Même animation d'entrée (fondu + léger glissement) que ProfilePage —
  // remplace l'ancien fondu+zoom avec flottement perpétuel, propre à
  // l'ancien design "carte de visite" de cette page.
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _load();

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

  Future<void> _load() async {
    try {
      final data = await _service.fetchCard(widget.slug);
      if (!mounted) return;
      setState(() {
        card = data;
        isLoading = false;
      });

      // Enregistrer automatiquement la vue
      _registerView();
    } catch (e) {
      // Carte introuvable (404 — profil sans carte publique valide) ou
      // erreur réseau : sans ce catch, l'exception n'était jamais
      // rattrapée (isLoading restait bloqué à true — écran quasi noir en
      // thème sombre, juste un spinner) et si l'utilisateur revenait en
      // arrière avant la résolution de la requête, le setState arrivait
      // après dispose() et plantait. On bascule sur l'état "Carte non
      // trouvée" déjà géré par build() (card == null).
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _registerView() async {
    // Le propriétaire qui consulte sa propre carte (aperçu, ou après avoir
    // été redirigé ici par erreur) ne doit jamais compter comme un scan.
    final viewerId = context.read<AuthProvider>().user?.id;
    final ownerId = int.tryParse(card?['user_id']?.toString() ?? '');
    if (viewerId != null && ownerId != null && viewerId == ownerId) return;

    try {
      await CardService.registerCardView(
        slug: widget.slug,
        source: 'qr_scan',
        // Permet au backend de dédupliquer : sans ça, un même visiteur
        // connecté qui rouvre plusieurs fois la carte (ex: navigue plusieurs
        // fois vers un même contact/profil) faisait remonter le compteur de
        // scans à chaque réouverture, au lieu d'une fois par visiteur.
        userId: viewerId,
      );
    } catch (_) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _showContactForm() async {
    await LeadCaptureSheet.show(
      context,
      slug: widget.slug,
      ownerName: card!['fullname'] ?? 'le proprietaire',
    );
  }

  String _getInitials(String name) {
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  /// Avatar tapable ouvrant la photo en plein écran (comme les applis
  /// modernes) — seulement si une vraie photo est disponible, sinon reste
  /// un simple rond d'initiales non interactif.
  Widget _buildAvatarCircle({
    required String avatarUrl,
    required double radius,
    required Color backgroundColor,
    Widget? child,
  }) {
    final circle = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage:
          avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
      child: child,
    );

    if (avatarUrl.isEmpty) return circle;

    return GestureDetector(
      onTap: () => PhotoViewer.show(context, avatarUrl),
      child: Hero(tag: avatarUrl, child: circle),
    );
  }

  String _getFirstName() {
    final fullName = card?['fullname']?.toString().trim() ?? '';
    if (fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  String _getFieldValue(String key) {
    final rawFields = card?['fields'];
    if (rawFields == null) return '';

    if (rawFields is Map<String, dynamic>) {
      final value = rawFields[key];
      if (value is String && value.isNotEmpty) return value.trim();
      if (value != null && value.toString().isNotEmpty) {
        return value.toString().trim();
      }
      return '';
    }

    if (rawFields is Map) {
      final value = rawFields[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString().trim();
      }
      return '';
    }

    debugPrint(
        '_getFieldValue($key) fields is not a Map: ${rawFields.runtimeType}');
    return '';
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Ignorer les erreurs de lancement URL.
    }
  }

  Future<void> _openEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPhone(String phone) async {
    if (phone.isEmpty) return;
    final sanitizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: sanitizedPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = colors.surface;
    final email = _getFieldValue('email');
    final phone = _getFieldValue('phone').isNotEmpty
        ? _getFieldValue('phone')
        : _getFieldValue('telephone').isNotEmpty
            ? _getFieldValue('telephone')
            : _getFieldValue('mobile');
    // Ville (digital_cards.city) — champ à plat comme job_title/company,
    // pas soumis à activated_fields (jamais géré via _getFieldValue, qui
    // ne lit que 'fields', un objet construit uniquement à partir des
    // réseaux sociaux/téléphone — 'location' n'y a jamais existé).
    final location = card?['city']?.toString() ?? '';
    final firstName = _getFirstName();
    final skills = _skillsList();
    final experiences = _getExperiences();
    final educations = _getEducations();
    final interests = _getInterests();
    final bio = card?['bio']?.toString().trim() ?? '';
    final socialProfiles = _socialProfiles();
    // Le backend renvoie 'avatar' (chemin relatif, ex. "avatars/foo.jpg"),
    // pas 'avatar_url' — il faut le préfixer avec le domaine de stockage,
    // sauf s'il s'agit déjà d'une URL complète (ex. photo Google OAuth).
    final rawAvatar = card?['avatar']?.toString() ?? '';
    final portraitUrl = rawAvatar.isEmpty
        ? ''
        : (rawAvatar.startsWith('http')
            ? rawAvatar
            : '${ApiEndpoints.storageUrl}/$rawAvatar');
    final fullName = card?['fullname']?.toString() ?? '';
    final jobTitle = card?['job_title']?.toString() ?? '';
    final company = card?['company']?.toString() ?? '';

    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        // Sans AppBar/bouton retour ici, un chargement bloqué (ou une
        // carte introuvable ci-dessous) laissait l'utilisateur bloqué sur
        // le web, sans geste natif "retour" comme sur mobile.
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              isDark ? Colors.white : _accentColor,
            ),
          ),
        ),
      );
    }

    if (card == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Text(
            'Carte non trouvée',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    final infoSection = _buildInfoSection(
      colors,
      email: email,
      phone: phone,
      location: location,
    );

    // Même chrome que ProfilePage (AppBar en verre dépoli + carte d'en-tête
    // + sections en cartes arrondies) — plutôt que l'ancien design "carte
    // de visite" propre à cette page, pour que le détail d'un profil
    // consulté depuis Explorer ait le même en-tête et le même contenu que
    // Mon profil. Pas de Scaffold.appBar : le SliverAppBar (flottant,
    // épinglé) est géré directement dans ce CustomScrollView.
    return Scaffold(
      backgroundColor: backgroundColor,
      // Cette page est parfois ouverte via un PageRouteBuilder à transition
      // personnalisée (depuis la liste des contacts), qui — contrairement à
      // MaterialPageRoute sur iOS — n'active pas le geste natif de retour
      // par glissement. On le réimplémente ici : glisser vers la droite
      // referme la page et revient à la liste des contacts.
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 250 &&
              Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: CustomScrollView(
          slivers: [
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
                        alpha: isDark ? 0.32 : 0.5,
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
                fullName.isEmpty ? 'Profil' : fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              centerTitle: true,
            ),
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
                        _buildHeaderCard(
                          colors: colors,
                          fullName: fullName,
                          jobTitle: jobTitle,
                          company: company,
                          bio: bio,
                          avatarUrl: portraitUrl,
                          experiences: experiences,
                          skills: skills,
                          email: email,
                          firstName: firstName,
                        ),
                        const SizedBox(height: 16),
                        if (socialProfiles.isNotEmpty) ...[
                          _buildSocialNetworks(colors, socialProfiles),
                          const SizedBox(height: 16),
                        ],
                        if (infoSection != null) ...[
                          infoSection,
                          const SizedBox(height: 16),
                        ],
                        _buildExperiencesSection(colors, experiences),
                        const SizedBox(height: 16),
                        _buildEducationsSection(colors, educations),
                        const SizedBox(height: 16),
                        _buildSkillsSection(colors, skills),
                        const SizedBox(height: 16),
                        _buildInterestsSection(colors, interests),
                        const SizedBox(
                            height: 40 + BottomNavMetrics.reservedHeight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte d'en-tête — même structure que ProfilePage._buildProfileHeader
  // (avatar, nom, poste/entreprise, bio, stats, actions), sans les
  // affordances d'édition (pas de badge appareil photo, pas de bouton
  // Modifier) puisqu'il ne s'agit jamais de son propre profil ici. Le
  // "Kart score" n'a pas d'équivalent (calculé côté profil à partir de son
  // propre modèle de complétion, non exposé publiquement) : la rangée de
  // stats se limite donc à Expérience/Compétences.
  Widget _buildHeaderCard({
    required ColorScheme colors,
    required String fullName,
    required String jobTitle,
    required String company,
    required String bio,
    required String avatarUrl,
    required List<dynamic> experiences,
    required List<String> skills,
    required String email,
    required String firstName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBackground =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final experienceYears = _computeExperienceYears(experiences);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withValues(alpha: 0.12),
            _accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_accentColor, _accentColor.withValues(alpha: 0.7)],
                  ),
                ),
                child: _buildAvatarCircle(
                  avatarUrl: avatarUrl,
                  radius: 32,
                  backgroundColor: avatarBackground,
                  child: avatarUrl.isEmpty
                      ? Text(
                          _getInitials(fullName),
                          style: TextStyle(
                            color: _accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
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
                      // 2 lignes plutôt que la troncature à 1 ligne — un nom
                      // long passe à la ligne au lieu d'être coupé par "...".
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _accentColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ExpandableText(
                        bio,
                        maxLines: 3,
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
                    icon: Icons.star_outline_rounded,
                    label: 'Compétences',
                    // Juste le nombre — même choix que ProfilePage.
                    value: skills.isNotEmpty ? '${skills.length}' : '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Contacter/Partager directement depuis la carte publique n'est
          // proposé que si ce profil est déjà un contact (scanné, ou
          // demande de mise en relation acceptée) — pas depuis une simple
          // consultation via Explorer, où le bon chemin est "Se connecter"
          // (avec l'accord de l'autre).
          if (_isConnected) ...[
            _buildCallToActions(email: email, firstName: firstName),
            const SizedBox(height: 18),
            _buildSecondaryActions(),
          ] else ...[
            _buildConnectSection(fullName),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileStat(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    // Padding horizontal : sans lui, le texte (aligné à gauche) touchait
    // directement la ligne verticale de séparation — même fix que
    // ProfilePage._buildProfileStat.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _accentColor),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              // 8 plutôt que 9.5, letterSpacing resserré : "COMPÉTENCES"
              // tient sur une ligne sans être tronqué — même correctif que
              // ProfilePage._buildProfileStat.
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: colors.onSurface.withValues(alpha: 0.45),
            ),
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
        ],
      ),
    );
  }

  /// Somme les durées des expériences (start_date → end_date, ou
  /// aujourd'hui si toujours en cours), arrondie à l'année — même calcul
  /// que ProfilePage._computeExperienceYears, appliqué ici aux expériences
  /// de la carte consultée plutôt qu'aux siennes.
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

  Widget _buildCallToActions({
    required String email,
    required String firstName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            if (email.isNotEmpty) {
              _openEmail(
                  email); // Ouvre directement l'app mail, comme l'icône email
            } else {
              _showContactForm();
            }
          },
          icon: const Icon(Icons.mail_outline, size: 18),
          label: Text(
            'Contacter${firstName.isNotEmpty ? ' $firstName' : ''}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: readableForegroundOn(_accentColor),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final foregroundColor = isDark ? Colors.white : const Color(0xFF111827);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showContactForm,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text(
              'Partager',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (widget.contactId != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showHighlightPicker,
              icon: const Icon(Icons.bookmark_outline_rounded, size: 18),
              label: Text(
                _currentHighlightName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: BorderSide(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Bouton "Se connecter" — même widget que dans la liste Explorer,
  /// affiché à la place de Contacter/Partager tant que ce profil n'est pas
  /// encore un contact établi (mise en relation avec consentement mutuel).
  Widget _buildConnectSection(String fullName) {
    final targetUserId = card?['user_id'];
    final currentUserId = context.watch<AuthProvider>().user?.id;

    if (targetUserId == null) return const SizedBox.shrink();

    final id = int.tryParse(targetUserId.toString());
    if (id == null || id == currentUserId) return const SizedBox.shrink();

    return Center(
      child: ConnectActionButton(
        userId: id,
        userName: fullName.isNotEmpty ? fullName : 'ce profil',
        initialStatus: _connectionStatusFromCard(),
        initialRequestId: card?['connection_request_id'] != null
            ? int.tryParse(card!['connection_request_id'].toString())
            : null,
      ),
    );
  }

  /// Traduit le 'connection_status' renvoyé par le backend (voir
  /// DigitalCardQrController::show) en ConnectionStatus — sans ça, le
  /// bouton repartait toujours de "Se connecter" à chaque réouverture de
  /// la page, même après l'envoi (ou l'acceptation) d'une demande.
  ConnectionStatus _connectionStatusFromCard() {
    switch (card?['connection_status']) {
      case 'pending_sent':
        return ConnectionStatus.pendingSent;
      case 'pending_received':
        return ConnectionStatus.pendingReceived;
      default:
        return ConnectionStatus.none;
    }
  }

  /// Nom du highlight actuellement assigné à ce contact, ou "Highlight" (le
  /// bouton fait alors office d'invitation à en choisir un) si aucun.
  String _currentHighlightName() {
    final contactId = widget.contactId;
    if (contactId == null) return 'Highlight';

    // watch() pour que le libellé se mette à jour immédiatement après un
    // changement de highlight (sans watch, le texte resterait figé jusqu'au
    // prochain rebuild déclenché par autre chose).
    final groups = context.watch<ContactsProvider>().groups;
    for (final group in groups) {
      for (final c in group.contacts) {
        if (c.id == contactId && c.highlightId != null) {
          return group.highlight.name;
        }
      }
    }
    return 'Highlight';
  }

  // Contrairement à la version "checklist" de ProfilePage (LinkedIn/
  // Instagram/... rempli ou non, cf. CompletionSections), ce profil n'est
  // pas le sien : le contenu utile ici est une liste de liens cliquables,
  // pas un statut de complétion — seul le chrome de carte (icône + titre)
  // reprend celui de Profil.
  Widget _buildSocialNetworks(
      ColorScheme colors, List<Map<String, dynamic>> socialProfiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return _buildSection(
      colors: colors,
      icon: Icons.share_outlined,
      title: 'Réseaux sociaux',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          // Icône/texte réduits + espacements resserrés : au format
          // d'avant, seuls 2 réseaux tenaient sur la première ligne avant
          // de passer à la ligne — 3 tiennent maintenant confortablement.
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: socialProfiles.map((profile) {
              return OutlinedButton.icon(
                onPressed: () => _openUrl(profile['value'] as String),
                icon: profile['icon'] is IconData
                    ? Icon(
                        profile['icon'] as IconData,
                        color: profile['iconColor'] as Color,
                        size: 14,
                      )
                    : FaIcon(
                        profile['icon'],
                        color: profile['iconColor'] as Color,
                        size: 14,
                      ),
                label: Text(
                  profile['label'] as String,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: titleColor,
                  side: BorderSide(color: borderColor),
                  padding:
                      const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Ouvre un sélecteur permettant de déplacer ce contact vers un highlight
  /// (ou de l'en retirer). Uniquement disponible quand `widget.contactId`
  /// est renseigné (page ouverte depuis la liste des contacts).
  void _showHighlightPicker() {
    final contactId = widget.contactId;
    if (contactId == null) return;

    HapticFeedback.lightImpact();
    final highlightProvider = context.read<HighlightProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final colors = Theme.of(context).colorScheme;

    // Highlight actuellement assigné à ce contact (pour cocher l'élément
    // correspondant dans la liste), retrouvé parmi les groupes déjà chargés.
    int? currentHighlightId;
    for (final group in contactsProvider.groups) {
      for (final c in group.contacts) {
        if (c.id == contactId) {
          currentHighlightId = c.highlightId;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Déplacer vers un highlight',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (highlightProvider.highlights.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aucun highlight créé pour le moment.',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.remove_circle_outline_rounded,
                        color: colors.onSurface.withValues(alpha: 0.5)),
                    title: const Text('Sans highlight'),
                    trailing: currentHighlightId == null
                        ? Icon(Icons.check_rounded, color: colors.primary)
                        : null,
                    onTap: () => _assignHighlight(
                        sheetContext, contactsProvider, contactId, null),
                  ),
                  for (final h in highlightProvider.highlights)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bookmark_rounded,
                          color: Color(0xFFF59E0B)),
                      title: Text(h.name),
                      trailing: currentHighlightId == h.id
                          ? Icon(Icons.check_rounded, color: colors.primary)
                          : null,
                      onTap: () => _assignHighlight(
                          sheetContext, contactsProvider, contactId, h.id),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _assignHighlight(
    BuildContext sheetContext,
    ContactsProvider contactsProvider,
    int contactId,
    int? highlightId,
  ) async {
    final navigator = Navigator.of(sheetContext);
    final scaffoldMessenger = ScaffoldMessenger.of(sheetContext);
    try {
      await contactsProvider.moveContactToHighlight(contactId, highlightId);
      if (navigator.mounted) navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du déplacement du contact'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Chrome de carte partagé (même style que ProfilePage._buildSection/
  // _buildInfoRow), dupliqué localement plutôt qu'importé : ProfilePage ne
  // les expose pas, et CompletionSections a déjà sa propre copie du même
  // motif — cohérent avec le reste du code base.

  Widget _buildSection({
    required ColorScheme colors,
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    // Plus de carte (fond + bordure) : même traitement que ProfilePage —
    // le détail d'un profil (Explorer, ou fiche contact) respire plutôt
    // que d'empiler chaque section dans un encart.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: _accentColor),
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
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInfoRow(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: colors.onSurface.withValues(alpha: 0.4)),
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
              if (onTap != null)
                Icon(Icons.chevron_right,
                    size: 20, color: colors.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Divider(height: 1, color: colors.onSurface.withValues(alpha: 0.06));
  }

  /// "Informations personnelles" en lecture seule — email/téléphone restent
  /// masqués tant que ce profil n'est pas un contact établi (même règle de
  /// confidentialité que le reste de la page) ; `null` si rien à montrer,
  /// pour que l'appelant puisse sauter la section (et son espacement)
  /// entièrement plutôt que d'afficher une carte vide.
  Widget? _buildInfoSection(
    ColorScheme colors, {
    required String email,
    required String phone,
    required String location,
  }) {
    final rows = <Widget>[];
    void addRow(IconData icon, String label, String value,
        {VoidCallback? onTap}) {
      if (rows.isNotEmpty) rows.add(_buildDivider(colors));
      rows.add(_buildInfoRow(colors,
          icon: icon, label: label, value: value, onTap: onTap));
    }

    if (location.isNotEmpty) {
      addRow(Icons.location_on_outlined, 'Localisation', location);
    }
    if (email.isNotEmpty && _isConnected) {
      addRow(Icons.email_outlined, 'Adresse email', email,
          onTap: () => _openEmail(email));
    }
    if (phone.isNotEmpty && _isConnected) {
      addRow(Icons.phone_outlined, 'Téléphone', phone,
          onTap: () => _openPhone(phone));
    }

    if (rows.isEmpty) return null;
    return _buildSection(
      colors: colors,
      icon: Icons.person_outline,
      title: 'Mes coordonnées',
      children: rows,
    );
  }

  // Même widget [SkillChip] que "Compétences" dans le profil (cf.
  // CompletionSections), affiché en lecture seule (sans onDelete).
  Widget _buildSkillsSection(ColorScheme colors, List<String> skills) {
    return _buildSection(
      colors: colors,
      icon: Icons.psychology_outlined,
      title: 'Compétences',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: skills.isEmpty
              ? Text(
                  'Aucune compétence ajoutée',
                  style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withValues(alpha: 0.4)),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) =>
                          SkillChip(label: s, color: const Color(0xFF10B981)))
                      .toList(),
                ),
        ),
      ],
    );
  }

  // Même widget [SkillChip] que "Centre d'intérêt" dans le profil, lecture
  // seule — cf. _buildSkillsSection.
  Widget _buildInterestsSection(ColorScheme colors, List<String> interests) {
    return _buildSection(
      colors: colors,
      icon: Icons.interests_outlined,
      title: "Centre d'intérêt",
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: interests.isEmpty
              ? Text(
                  "Aucun centre d'intérêt ajouté",
                  style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface.withValues(alpha: 0.4)),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests
                      .map((i) =>
                          SkillChip(label: i, color: _interestsAccentColor))
                      .toList(),
                ),
        ),
      ],
    );
  }

  /// "Expériences" — même présentation que la section Profil
  /// (CompletionSections._buildExperiencesSection) : aperçu des 2 plus
  /// récentes en frise, plus "Voir tout" qui ouvre la liste complète en
  /// lecture seule (pas de formulaire d'édition ici, ce n'est pas son
  /// propre profil).
  Widget _buildExperiencesSection(
      ColorScheme colors, List<dynamic> experiences) {
    final sorted = [...experiences]..sort((a, b) {
        final ma = a as Map? ?? {};
        final mb = b as Map? ?? {};
        final startA = DateTime.tryParse(ma['start_date']?.toString() ?? '');
        final startB = DateTime.tryParse(mb['start_date']?.toString() ?? '');
        if (startA == null || startB == null) return 0;
        return startB.compareTo(startA);
      });
    final preview = sorted.take(2).toList();

    return _buildSection(
      colors: colors,
      icon: Icons.work_outline_rounded,
      title: 'Expériences',
      trailing: sorted.isEmpty
          ? null
          : GestureDetector(
              onTap: () => _showAllExperiences(colors, sorted),
              child: Text(
                'Voir tout',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _accentColor),
              ),
            ),
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Text(
              'Aucune expérience',
              style: TextStyle(
                  fontSize: 14, color: colors.onSurface.withValues(alpha: 0.4)),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Column(
              children: preview.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value as Map? ?? {};
                return _PublicTimelineItem(
                  title: item['title']?.toString() ?? '',
                  company: item['company']?.toString() ?? '',
                  period: _formatExperiencePeriod(
                      item['start_date']?.toString(),
                      item['end_date']?.toString()),
                  description: item['description']?.toString() ?? '',
                  isLast: i == preview.length - 1,
                  accentColor: _accentColor,
                  colors: colors,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Bottom sheet listant toutes les expériences en lecture seule — même
  /// présentation (poignée, titre, fond `colorScheme.surface`, coins
  /// arrondis, `DraggableScrollableSheet`) que
  /// CompletionSections._showAllExperiences côté profil.
  void _showAllExperiences(ColorScheme colors, List<dynamic> sorted) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Expériences',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface),
              ),
              const SizedBox(height: 20),
              ...sorted.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value as Map? ?? {};
                return _PublicTimelineItem(
                  title: item['title']?.toString() ?? '',
                  company: item['company']?.toString() ?? '',
                  period: _formatExperiencePeriod(
                      item['start_date']?.toString(),
                      item['end_date']?.toString()),
                  description: item['description']?.toString() ?? '',
                  isLast: i == sorted.length - 1,
                  accentColor: _accentColor,
                  colors: colors,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// "2023 – Aujourd'hui" / "2021 – 2023" — même format que
  /// CompletionSections._formatExperiencePeriod côté profil.
  String _formatExperiencePeriod(String? start, String? end) {
    final startYear = _experienceYear(start);
    final endYear =
        (end != null && end.isNotEmpty) ? _experienceYear(end) : null;
    return '$startYear – ${endYear ?? "Aujourd'hui"}';
  }

  String _experienceYear(String? date) {
    if (date == null || date.isEmpty) return '';
    final parsed = DateTime.tryParse(date);
    return parsed != null ? parsed.year.toString() : date;
  }

  /// "Formation" — même présentation que la section Profil
  /// (CompletionSections._buildEducationsSection) : aperçu des 3 plus
  /// récentes, puis "Voir tout" (lecture seule) au-delà — même principe que
  /// "Expériences" ci-dessus.
  Widget _buildEducationsSection(ColorScheme colors, List<dynamic> educations) {
    final sorted = [...educations]..sort((a, b) {
        final ma = a as Map? ?? {};
        final mb = b as Map? ?? {};
        final ya = int.tryParse(ma['start_year']?.toString() ?? '') ?? 0;
        final yb = int.tryParse(mb['start_year']?.toString() ?? '') ?? 0;
        return yb.compareTo(ya);
      });
    final preview = sorted.take(3).toList();

    return _buildSection(
      colors: colors,
      icon: Icons.school_outlined,
      title: 'Formation',
      trailing: sorted.length <= 3
          ? null
          : GestureDetector(
              onTap: () => _showAllEducations(colors, sorted),
              child: Text(
                'Voir tout',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _accentColor),
              ),
            ),
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Text(
              'Aucune formation ajoutée',
              style: TextStyle(
                  fontSize: 14, color: colors.onSurface.withValues(alpha: 0.4)),
            ),
          )
        else
          ...preview.asMap().entries.map((entry) =>
              _buildEducationRow(colors, entry.value, entry.key > 0)),
      ],
    );
  }

  /// Une ligne "Formation" — extrait pour être réutilisé à la fois dans
  /// l'aperçu et dans le "Voir tout" (_showAllEducations).
  Widget _buildEducationRow(
      ColorScheme colors, dynamic entry, bool showDivider) {
    final item = entry as Map? ?? {};
    final degree = item['degree']?.toString() ?? '';
    final school = item['school']?.toString() ?? '';
    final field = item['field']?.toString() ?? '';
    final startYear = item['start_year']?.toString() ?? '';
    final endYear = item['end_year']?.toString() ?? '';

    return Column(
      children: [
        if (showDivider) _buildDivider(colors),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_outlined,
                    size: 18, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      degree,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      school,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (field.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              field,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        if (field.isNotEmpty) const SizedBox(width: 8),
                        Text(
                          '$startYear - $endYear',
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurface.withValues(alpha: 0.45)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bottom sheet listant toutes les formations en lecture seule — même
  /// présentation que _showAllExperiences.
  void _showAllEducations(ColorScheme colors, List<dynamic> sorted) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(
                'Formation',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface),
              ),
              const SizedBox(height: 20),
              ...sorted.asMap().entries.map((entry) =>
                  _buildEducationRow(colors, entry.value, entry.key > 0)),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _skillsList() {
    return _getFieldValue('skills')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _socialProfiles() {
    final profiles = <Map<String, dynamic>>[];

    if (_getFieldValue('linkedin').isNotEmpty) {
      profiles.add({
        'label': 'LinkedIn',
        'icon': FontAwesomeIcons.linkedin,
        'value': _getFieldValue('linkedin'),
        'bgColor': const Color(0xFFE8F0FE),
        'iconColor': const Color(0xFF0A66C2),
      });
    }
    if (_getFieldValue('x').isNotEmpty) {
      profiles.add({
        'label': 'X',
        'icon': FontAwesomeIcons.xTwitter,
        'value': _getFieldValue('x'),
        'bgColor': const Color(0xFFF3F4F6),
        'iconColor': const Color(0xFF000000),
      });
    }
    if (_getFieldValue('instagram').isNotEmpty) {
      profiles.add({
        'label': 'Instagram',
        'icon': FontAwesomeIcons.instagram,
        'value': _getFieldValue('instagram'),
        'bgColor': const Color(0xFFFCE7F3),
        'iconColor': const Color(0xFFE4405F),
      });
    }
    if (_getFieldValue('facebook').isNotEmpty) {
      profiles.add({
        'label': 'Facebook',
        'icon': FontAwesomeIcons.facebook,
        'value': _getFieldValue('facebook'),
        'bgColor': const Color(0xFFEAF2FF),
        'iconColor': const Color(0xFF1877F2),
      });
    }
    if (_getFieldValue('github').isNotEmpty) {
      profiles.add({
        'label': 'GitHub',
        'icon': FontAwesomeIcons.github,
        'value': _getFieldValue('github'),
        'bgColor': const Color(0xFFF3F4F6),
        'iconColor': const Color(0xFF111827),
      });
    }
    if (_getFieldValue('website').isNotEmpty) {
      profiles.add({
        'label': 'Website',
        'icon': FontAwesomeIcons.globe,
        'value': _getFieldValue('website'),
        'bgColor': const Color(0xFFEFF6FF),
        'iconColor': _accentColor,
      });
    }

    final phone = _getFieldValue('phone');
    final ownerName = card?['fullname']?.toString() ?? '';

    // Même principe que l'email/téléphone affichés dans l'en-tête : pas de
    // WhatsApp (dérivé du numéro) tant que ce profil n'est pas un contact
    // établi.
    if (phone.isNotEmpty && _isConnected) {
      final formattedPhone = phone.replaceAll(RegExp(r'\D'), '');

      profiles.add({
        'label': 'WhatsApp',
        'icon': FontAwesomeIcons.whatsapp,
        'value': 'https://wa.me/$formattedPhone?text=Bonjour%20$ownerName',
        'bgColor': const Color(0xFFE7FCEB),
        'iconColor': const Color(0xFF25D366),
      });
    }

    return profiles;
  }

  List<dynamic> _getExperiences() {
    final experiences = card?['experiences'];
    if (experiences is List) return experiences;
    return [];
  }

  List<dynamic> _getEducations() {
    final educations = card?['educations'];
    if (educations is List) return educations;
    return [];
  }

  List<String> _getInterests() {
    final interests = card?['interests'];
    if (interests is List) return interests.map((e) => e.toString()).toList();
    return [];
  }
}

/// Une ligne de la frise "Expériences", en lecture seule — même visuel que
/// CompletionSections._ExperienceTimelineItem côté profil (pastille + ligne
/// verticale, titre/entreprise/période/description), sans le chevron/tap
/// puisqu'il n'y a rien à éditer sur un profil consulté.
class _PublicTimelineItem extends StatelessWidget {
  final String title;
  final String company;
  final String period;
  final String description;
  final bool isLast;
  final Color accentColor;
  final ColorScheme colors;

  const _PublicTimelineItem({
    required this.title,
    required this.company,
    required this.period,
    required this.description,
    required this.isLast,
    required this.accentColor,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: accentColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: accentColor.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface),
                  ),
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      company,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: accentColor),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    period,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: colors.onSurface.withValues(alpha: 0.45)),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ExpandableText(
                      description,
                      maxLines: 3,
                      accentColor: accentColor,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colors.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../data/public_card_service.dart';
import '../../../shared/services/card_service.dart';
import '../widgets/lead_capture_sheet.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../contacts/providers/highlight_provider.dart';

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

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _appearController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> exampleMessages = [
    "Ravi de vous rencontrer ! 🤝",
    "Merci pour cet échange enrichissant",
    "Restons en contact 📲",
    "Au plaisir de collaborer ensemble",
  ];

  @override
  void initState() {
    super.initState();
    _load();

    // Animation flottante
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Animation d'apparition
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutBack),
    );

    _appearController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _service.fetchCard(widget.slug);
    setState(() {
      card = data;
      isLoading = false;
    });

    // Enregistrer automatiquement la vue
    _registerView();
  }

  Future<void> _registerView() async {
    try {
      await CardService.registerCardView(
        slug: widget.slug,
        source: 'qr_scan',
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
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
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
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final email = _getFieldValue('email');
    final phone = _getFieldValue('phone').isNotEmpty
        ? _getFieldValue('phone')
        : _getFieldValue('telephone').isNotEmpty
            ? _getFieldValue('telephone')
            : _getFieldValue('mobile');
    final location = _getFieldValue('location');
    final firstName = _getFirstName();
    final skills = _skillsList();
    final experiences = _getExperiences();
    final educations = _getEducations();
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHero(
                            isDark: isDark,
                            fullName: fullName,
                            jobTitle: jobTitle,
                            company: company,
                            location: location,
                            email: email,
                            phone: phone,
                            avatarUrl: portraitUrl,
                          ),
                          _buildSectionDivider(),
                          _buildCallToActions(
                            email: email,
                            firstName: firstName,
                          ),
                          const SizedBox(height: 18),
                          _buildSecondaryActions(),
                          if (socialProfiles.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _buildSocialNetworks(socialProfiles),
                          ],
                          if (_getFieldValue('bio').isNotEmpty) ...[
                            _buildSectionDivider(),
                            _buildAbout(isDark),
                          ],
                          if (skills.isNotEmpty) ...[
                            _buildSectionDivider(),
                            _buildSkills(isDark, skills),
                          ],
                          _buildSectionDivider(),
                          _buildExperienceTimeline(isDark, experiences),
                          _buildSectionDivider(),
                          _buildEducation(isDark, educations),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero({
    required bool isDark,
    required String fullName,
    required String jobTitle,
    required String company,
    required String location,
    required String email,
    required String phone,
    required String avatarUrl,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final chipBackground =
        isDark ? const Color(0xFF111827) : const Color(0xFFF0FDF4);
    final chipBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7);
    final avatarBackground =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final avatarTextColor = isDark ? _accentColor : _accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: titleColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipBorder),
          ),
          child: Text(
            'OUVERT AUX OPPORTUNITÉS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF2563EB) : const Color(0xFF166534),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      height: 1.05,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ROLE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              jobTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMPANY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty ||
                      email.isNotEmpty ||
                      phone.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    if (location.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (email.isNotEmpty || phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (email.isNotEmpty)
                            _buildInlineContactChip(
                              icon: Icons.email_outlined,
                              label: email,
                              onTap: () => _openEmail(email),
                              titleColor: titleColor,
                              borderColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                            ),
                          if (phone.isNotEmpty)
                            _buildInlineContactChip(
                              icon: Icons.phone_outlined,
                              label: phone,
                              onTap: () => _openPhone(phone),
                              titleColor: titleColor,
                              borderColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE5E7EB),
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 20),
            _buildAvatarCircle(
              avatarUrl: avatarUrl,
              radius: 40,
              backgroundColor: avatarBackground,
              child: avatarUrl.isEmpty
                  ? Text(
                      _getInitials(fullName),
                      style: TextStyle(
                        color: avatarTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInlineContactChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color titleColor,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _accentColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            foregroundColor: Colors.white,
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

  Widget _buildSocialNetworks(List<Map<String, dynamic>> socialProfiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réseaux sociaux',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: socialProfiles.map((profile) {
            return OutlinedButton.icon(
              onPressed: () => _openUrl(profile['value'] as String),
              icon: profile['icon'] is IconData
                  ? Icon(
                      profile['icon'] as IconData,
                      color: profile['iconColor'] as Color,
                      size: 16,
                    )
                  : FaIcon(
                      profile['icon'],
                      color: profile['iconColor'] as Color,
                      size: 16,
                    ),
              label: Text(
                profile['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: titleColor,
                side: BorderSide(color: borderColor),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          }).toList(),
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

  Widget _buildAbout(bool isDark) {
    final bio = _getFieldValue('bio');
    if (bio.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A propos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          bio,
          style: TextStyle(
            fontSize: 14,
            height: 1.7,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSkills(bool isDark, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compétences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                skill,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExperienceTimeline(bool isDark, List<dynamic> experiences) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final iconColor = isDark ? _accentColor : _accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              'Experience',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (experiences.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Aucune expérience',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ] else ...[
          Column(
            children: experiences.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map? ?? {};
              final title = item['title']?.toString() ?? '';
              final company = item['company']?.toString() ?? '';
              final startDate = item['start_date']?.toString() ?? '';
              final endDate = item['end_date']?.toString() ?? '';
              final description = item['description']?.toString() ?? '';
              final isLast = index == experiences.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          if (index != 0)
                            Container(
                              width: 1,
                              height: 18,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF3F4F6),
                            ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 1,
                              height: 60,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF3F4F6),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                          if (company.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            endDate.isNotEmpty
                                ? '$startDate — $endDate'
                                : '$startDate — Present',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEducation(bool isDark, List<dynamic> educations) {
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final surfaceColor =
        isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final accentColor = isDark ? _accentColor : _accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Education',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (educations.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Aucune éducation',
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ] else ...[
          Column(
            children: educations.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value as Map? ?? {};
              final degree = item['degree']?.toString() ?? '';
              final school = item['school']?.toString() ?? '';
              final field = item['field']?.toString() ?? '';
              final startYear = item['start_year']?.toString() ?? '';
              final endYear = item['end_year']?.toString() ?? '';
              final isLast = index == educations.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      degree,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (field.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              field,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (field.isNotEmpty) const SizedBox(width: 10),
                        Text(
                          '$startYear — $endYear',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
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

    if (phone.isNotEmpty) {
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
}

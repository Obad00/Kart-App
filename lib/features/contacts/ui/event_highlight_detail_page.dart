import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../auth/providers/auth_provider.dart';
import '../../company_community/ui/event_participant_scan_page.dart';
import '../../company_community/widgets/participant_list_widgets.dart';
import '../../explore/models/explore_user.dart';
import '../../public_card/ui/public_card_page.dart';
import '../../../shared/services/card_service.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/expandable_text.dart';

/// Ouverte en tapant sur un highlight d'événement (voir highlight_bar.dart) :
/// affiche les infos de l'événement (thème, lieu, date, description) ainsi
/// que les autres participants déjà inscrits, avec la possibilité de se
/// connecter à eux directement — même bouton "glisser pour se connecter"
/// que dans Explorer.
class EventHighlightDetailPage extends StatefulWidget {
  final int eventId;
  final String fallbackName;

  const EventHighlightDetailPage({
    super.key,
    required this.eventId,
    required this.fallbackName,
  });

  @override
  State<EventHighlightDetailPage> createState() =>
      _EventHighlightDetailPageState();
}

class _EventHighlightDetailPageState extends State<EventHighlightDetailPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _event;
  List<ExploreUser> _attendees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await CardService.fetchEventAttendees(widget.eventId);
      final attendees = (data['attendees'] as List? ?? [])
          .map((e) => ExploreUser.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _event = data['event'] as Map<String, dynamic>?;
        _attendees = attendees;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data is Map
                    ? (e.response?.data as Map)['message']?.toString()
                    : null) ??
                'Impossible de charger cet événement.'
            : 'Impossible de charger cet événement.';
        _isLoading = false;
      });
    }
  }

  /// Ouvre la MÊME carte détail que "voir tout" dans Explorer — remonté
  /// côté produit : le détail d'un participant doit être "conforme" à ce
  /// design-là, pas une fiche maison. Un attendee a toujours une carte
  /// publique (attendees() ne renvoie que des digitalCard.is_public=true),
  /// donc cardSlug est toujours renseigné ici.
  void _openAttendeeCard(ExploreUser user) {
    final slug = user.cardSlug;
    if (slug == null || slug.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicCardPage(
          slug: slug,
          initialConnectionStatus: user.connectionStatus,
          initialConnectionRequestId: user.connectionRequestId,
          // Coordonnées visibles uniquement si le backend les a envoyées
          // (collaborateur/admin de l'entreprise organisatrice) — cf.
          // EventController::attendees().
          organizerContactEmail: user.email,
          organizerContactPhone: user.phone,
        ),
      ),
    );
  }

  static const _frMonths = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  // Formatage manuel plutôt que DateFormat(locale: 'fr_FR') : ce dernier
  // exige initializeDateFormatting(), jamais appelé ailleurs dans l'app, et
  // lèverait une LocaleDataException à l'exécution.
  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return null;
    final month = _frMonths[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "${date.day} $month ${date.year} à ${hour}h$minute";
  }

  /// Icône "scanner les participants" — visible uniquement pour un
  /// collaborateur de l'entreprise qui a créé CET événement
  /// (event.company_id === son company_id), pas pour un participant
  /// lambda : c'est ce contexte-là qui lève toute ambiguïté avec le scan
  /// habituel (carte → ajout aux contacts).
  bool _canScanParticipants(BuildContext context) {
    final companyId = _event?['company_id'];
    final userCompanyId = context.read<AuthProvider>().user?.companyId;
    return companyId != null &&
        userCompanyId != null &&
        companyId == userCompanyId &&
        !_eventHasEnded();
  }

  /// Un événement terminé n'a plus besoin d'être scanné — plus personne
  /// n'arrive à ce moment-là. Même calcul que CompanyEventSummary.hasEnded
  /// côté "Ma communauté", reproduit ici faute de date de fin dans la
  /// réponse d'attendees() sous une autre forme.
  bool _eventHasEnded() {
    final endsAt = _event?['ends_at'] as String?;
    if (endsAt == null || endsAt.isEmpty) return false;
    final date = DateTime.tryParse(endsAt);
    return date != null && date.isBefore(DateTime.now());
  }

  void _openParticipantScan(BuildContext context) {
    final event = _event;
    if (event == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventParticipantScanPage(
          eventId: widget.eventId,
          eventName: event['name'] as String? ?? widget.fallbackName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    final appBar = GlassAppBar(
      title: Text(event?['name'] ?? widget.fallbackName),
      actions: event != null && _canScanParticipants(context)
          ? [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Scanner les participants',
                onPressed: () => _openParticipantScan(context),
              ),
            ]
          : null,
    );

    return Scaffold(
      // extendBodyBehindAppBar + le padding top ci-dessous (au lieu d'un
      // SafeArea classique) : la liste défile réellement sous la barre en
      // verre dépoli, qui a donc du contenu à flouter au scroll — pas
      // seulement une bande de couleur unie.
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: _isLoading
          ? const AppLoader(label: "Chargement de l'événement...")
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      appBar.preferredSize.height +
                          MediaQuery.of(context).padding.top +
                          16,
                      16,
                      32,
                    ),
                    children: [
                      if (event != null)
                        _EventInfoCard(event: event, formatDate: _formatDate),
                      const SizedBox(height: 24),
                      Text(
                        _attendees.isEmpty
                            ? 'Aucun autre participant pour le moment'
                            : 'Participants (${_attendees.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Même ParticipantListTile/ParticipantDetailSheet que
                      // "Ma communauté" (remonté côté produit : les deux
                      // listes de participants avaient chacune leur propre
                      // design) — sans présence (non pertinente ici) et
                      // sans mail/téléphone pour qui n'est pas
                      // collaborateur/admin de l'entreprise organisatrice :
                      // le backend ne les envoie tout simplement pas dans
                      // ce cas (cf. EventController::attendees()).
                      ..._attendees.map(
                        (user) => ParticipantListTile(
                          displayName: user.name,
                          subtitle: [user.jobTitle, user.company]
                              .where((s) => (s ?? '').isNotEmpty)
                              .join(' · '),
                          onTap: () => _openAttendeeCard(user),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String? Function(String?) formatDate;

  const _EventInfoCard({required this.event, required this.formatDate});

  /// "#RRGGBB" (ou "RRGGBB") -> Color ; repli sur le bleu KART pour toute
  /// valeur absente ou mal formée, jamais d'exception ici.
  static Color _parseBrandColor(String? hex) {
    const fallback = Color(0xFF1D4ED8);
    if (hex == null) return fallback;
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? fallback : Color(0xFF000000 | value);
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = event['theme'] as String?;
    final location = event['location'] as String?;
    final description = event['description'] as String?;
    final startsAt = formatDate(event['starts_at'] as String?);

    // Dégradé aux couleurs de l'entreprise organisatrice (brand_color =
    // couleur de l'événement, sinon celle de l'entreprise, sinon le bleu
    // KART — cf. Event::qrColor() côté backend) au lieu du bleu→violet
    // fixe d'avant, sans rapport avec la marque (remonté côté produit).
    final brand = _parseBrandColor(event['brand_color'] as String?);
    // Affiche ajoutée à la création de l'événement (cf. EventCreateView.vue
    // côté CRM) — remonté côté produit : elle n'apparaissait nulle part
    // dans l'app, seulement sur la page publique d'inscription.
    final imageUrl = event['image_url'] as String?;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [brand, _darken(brand, 0.22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                // CachedNetworkImage (pas Image.network) : l'affiche était
                // retéléchargée en entier à chaque ouverture du highlight,
                // d'où l'impression qu'elle "tarde à venir" — remonté côté
                // produit. Un placeholder shimmer comble l'attente au
                // premier chargement au lieu d'un bloc vide.
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.white.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),
                  ),
                  // Une affiche qui ne charge pas (réseau, image supprimée
                  // côté serveur) ne doit pas casser le reste de la fiche.
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['name'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if ((theme ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      theme!,
                      style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (startsAt != null)
                    _InfoLine(
                        icon: Icons.calendar_today_rounded, label: startsAt),
                  if ((location ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoLine(
                        icon: Icons.location_on_rounded, label: location!),
                  ],
                  if ((description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                        height: 1, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 14),
                    ExpandableText(
                      description!,
                      maxLines: 3,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4),
                      accentColor: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoLine({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../explore/models/explore_user.dart' show ConnectionStatus;
import '../../explore/widgets/connect_action_button.dart';
import '../models/event_participant_summary.dart';
import '../services/company_community_service.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Détail d'un événement de l'entreprise : statistiques inscrits/présents/
/// walk-ins + table "Participant / Statut / Profil KART" (cf. maquette
/// produit fournie). Même charpente Scaffold+GlassAppBar que
/// CompanyDetailPage (Explorer) pour rester visuellement cohérent.
class CompanyEventParticipantsPage extends StatefulWidget {
  final int eventId;
  final String eventName;
  // Lien d'inscription publique de cet événement (cf. Event::public_url
  // côté backend) — null pour un événement chargé par une version d'API
  // antérieure à ce champ : le bouton de partage est alors simplement
  // masqué plutôt que de partager une URL vide.
  final String? publicUrl;

  const CompanyEventParticipantsPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.publicUrl,
  });

  @override
  State<CompanyEventParticipantsPage> createState() =>
      _CompanyEventParticipantsPageState();
}

class _CompanyEventParticipantsPageState
    extends State<CompanyEventParticipantsPage> {
  final _service = CompanyCommunityService();
  List<EventParticipantSummary> _participants = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;

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
      final result = await _service.fetchParticipants(widget.eventId);
      if (!mounted) return;
      setState(() {
        _participants = result.participants;
        _stats = result.stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les participants.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = GlassAppBar(
      title: Text(widget.eventName),
      actions: [
        if (widget.publicUrl != null && widget.publicUrl!.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: "Partager le lien d'inscription",
            onPressed: _shareRegistrationLink,
          ),
      ],
    );
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: _buildBody(colors, topPadding),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: topPadding, child: glassAppBar),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colors, double topPadding) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 32),
      children: [
        _buildStatsRow(colors),
        const SizedBox(height: 20),
        if (_participants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Aucun participant pour le moment',
                style:
                    TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ..._participants.map(
            (p) => _ParticipantRow(
              participant: p,
              onTap: () => _openParticipantSheet(p),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme colors) {
    final registered = _stats['registered'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final walkIns = _stats['walk_ins'] as int? ?? 0;
    final absent = _stats['not_present'] as int? ?? (registered - present);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _StatTile(
                    label: 'Inscrits',
                    value: registered,
                    color: colors.onSurface)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    label: 'Présents', value: present, color: Colors.green)),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    label: 'Absents',
                    value: absent,
                    color: colors.onSurface.withValues(alpha: 0.6))),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
                    label: 'Walk-in',
                    value: walkIns,
                    color: Colors.amber.shade700)),
          ],
        ),
        if (walkIns > 0) ...[
          const SizedBox(height: 8),
          // "Walk-in" n'est pas parlant tel quel (question remontée côté
          // produit) — la définition est donnée là où le chiffre s'affiche.
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: colors.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Walk-in : venu·e le jour J sans s\'être inscrit·e en ligne.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Partage le lien d'inscription publique via la feuille de partage du
  /// système (WhatsApp, LinkedIn, mail… selon ce qui est installé) — même
  /// finalité que l'onglet "Partager" du CRM, remonté côté produit pour
  /// l'app aussi, là où l'admin voit déjà ses inscrits.
  Future<void> _shareRegistrationLink() async {
    final link = widget.publicUrl;
    if (link == null || link.isEmpty) return;

    final text = 'Inscrivez-vous à ${widget.eventName} : $link';
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (e) {
      if (!mounted) return;
      FeedbackOverlay.showError(
        context,
        title: 'Erreur',
        subtitle: 'Impossible d\'ouvrir le partage.',
      );
    }
  }

  /// Fiche d'un inscrit : ses coordonnées (mail/téléphone) et de quoi se
  /// mettre en relation avec lui comme partout ailleurs dans Explorer —
  /// remonté côté produit : la liste seule ne permettait ni de voir ces
  /// informations ni de "se connecter à eux".
  void _openParticipantSheet(EventParticipantSummary participant) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ParticipantSheet(participant: participant),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

/// Une ligne "Participant / Statut / Profil KART" — cf. tableau demandé
/// côté produit (dashboard superadmin fourni en exemple).
class _ParticipantRow extends StatelessWidget {
  final EventParticipantSummary participant;
  final VoidCallback? onTap;

  const _ParticipantRow({required this.participant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _themeBlue.withValues(alpha: 0.12),
              child: Text(
                participant.displayName.isNotEmpty
                    ? participant.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w800,
                    color: _themeBlue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.displayName,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (participant.jobTitle?.isNotEmpty == true ||
                      participant.company?.isNotEmpty == true)
                    Text(
                      [participant.jobTitle, participant.company]
                          .where((s) => s?.isNotEmpty == true)
                          .join(' · '),
                      style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.55)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  label: participant.isPresent ? 'Présent' : 'Absent',
                  icon: participant.isPresent
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: participant.isPresent ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 4),
                _Badge(
                  label: participant.hasAccount ? 'KART créé' : 'Pas encore',
                  icon: participant.hasAccount
                      ? Icons.verified_rounded
                      : Icons.hourglass_empty_rounded,
                  color: participant.hasAccount ? _themeBlue : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Fiche d'un inscrit, ouverte au tap sur une ligne : coordonnées visibles
/// (mail/téléphone) + mise en relation, réutilisant le ConnectActionButton
/// d'Explorer plutôt qu'un bouton maison — même comportement et mêmes états
/// (Envoyer / Envoyée / Accepter-Refuser) que partout ailleurs dans l'app.
class _ParticipantSheet extends StatelessWidget {
  final EventParticipantSummary participant;

  const _ParticipantSheet({required this.participant});

  ConnectionStatus get _status {
    switch (participant.connectionStatus) {
      case 'pending_sent':
        return ConnectionStatus.pendingSent;
      case 'pending_received':
        return ConnectionStatus.pendingReceived;
      case 'contact':
        return ConnectionStatus.contact;
      default:
        return ConnectionStatus.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: GlassSheet(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeBlue.withValues(alpha: 0.12),
                    child: Text(
                      participant.displayName.isNotEmpty
                          ? participant.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _themeBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participant.displayName,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        if (participant.jobTitle?.isNotEmpty == true ||
                            participant.company?.isNotEmpty == true)
                          Text(
                            [participant.jobTitle, participant.company]
                                .where((s) => s?.isNotEmpty == true)
                                .join(' · '),
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: participant.email,
              ),
              _SheetInfoRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: participant.phone,
              ),
              _SheetInfoRow(
                icon: Icons.event_available_outlined,
                label: 'Présence',
                value: participant.isPresent ? 'Présent' : 'Pas encore arrivé',
              ),
              const SizedBox(height: 18),
              // Pas de compte KART rattaché (walk-in pas encore inscrit) :
              // rien à quoi se connecter, on l'explique au lieu d'afficher
              // un bouton qui ne pourrait rien faire.
              if (participant.userId == null)
                Text(
                  "Ce visiteur n'a pas encore créé son compte KART — la mise en relation sera possible dès qu'il l'aura fait.",
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else if (_status == ConnectionStatus.contact)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Déjà dans vos contacts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                )
              else
                ConnectActionButton(
                  userId: participant.userId!,
                  userName: participant.displayName,
                  initialStatus: _status,
                  initialRequestId: participant.connectionRequestId,
                  compact: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _SheetInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colors.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value!,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

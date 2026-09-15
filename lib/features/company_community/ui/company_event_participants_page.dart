import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_app_bar.dart';
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

  const CompanyEventParticipantsPage({
    super.key,
    required this.eventId,
    required this.eventName,
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
    final glassAppBar = GlassAppBar(title: Text(widget.eventName));
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
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          ..._participants.map((p) => _ParticipantRow(participant: p)),
      ],
    );
  }

  Widget _buildStatsRow(ColorScheme colors) {
    final registered = _stats['registered'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final walkIns = _stats['walk_ins'] as int? ?? 0;

    return Row(
      children: [
        Expanded(child: _StatTile(label: 'Inscrits', value: registered, color: colors.onSurface)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Présents', value: present, color: Colors.green)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'Walk-in', value: walkIns, color: Colors.amber.shade700)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

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
                fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.55)),
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

  const _ParticipantRow({required this.participant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
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
                  fontFamily: 'Syne', fontWeight: FontWeight.w800, color: _themeBlue),
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
                        fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
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
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

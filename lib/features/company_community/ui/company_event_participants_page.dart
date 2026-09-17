import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../models/event_participant_summary.dart';
import '../services/company_community_service.dart';
import '../widgets/participant_list_widgets.dart';

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
  // Un événement terminé ne doit plus pouvoir être partagé — inutile
  // d'inviter à s'inscrire à quelque chose qui n'a plus lieu — cf. bouton
  // de partage plus bas, masqué dans ce cas.
  final bool eventHasEnded;

  const CompanyEventParticipantsPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.publicUrl,
    this.eventHasEnded = false,
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
    } on DioException catch (e) {
      if (!mounted) return;
      // Message qui dit ce qui s'est réellement passé plutôt qu'un
      // "Impossible de charger les participants" systématique — remonté
      // côté produit : un admin voyait cette erreur là où un collaborateur
      // du même événement n'avait aucun souci, impossible à comprendre
      // sans savoir si c'était un 403, une session expirée ou le réseau.
      setState(() {
        _error = _messageFor(e);
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

  String _messageFor(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage = e.response?.data is Map
        ? (e.response?.data as Map)['message']?.toString()
        : null;

    if (status == null) {
      return 'Connexion impossible. Vérifiez votre réseau.';
    }
    if (status == 401 || status == 403) {
      return serverMessage ??
          "Vous n'avez plus accès à cet événement (session expirée ou entreprise différente).";
    }
    if (status >= 500) {
      return 'Le serveur a rencontré une erreur ($status). Réessayez dans un instant.';
    }
    return serverMessage ?? 'Impossible de charger les participants ($status).';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = GlassAppBar(
      title: Text(widget.eventName),
      actions: [
        // Un événement terminé n'a plus vocation à être partagé — inutile
        // d'inviter à s'inscrire à quelque chose qui n'a plus lieu.
        if (!widget.eventHasEnded &&
            widget.publicUrl != null &&
            widget.publicUrl!.isNotEmpty)
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
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
            (p) => ParticipantListTile(
              displayName: p.displayName,
              subtitle: [p.jobTitle, p.company]
                  .where((s) => s?.isNotEmpty == true)
                  .join(' · '),
              isPresent: p.isPresent,
              hasAccount: p.hasAccount,
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
      builder: (_) => ParticipantDetailSheet(
        displayName: participant.displayName,
        subtitle: [participant.jobTitle, participant.company]
            .where((s) => s?.isNotEmpty == true)
            .join(' · '),
        email: participant.email,
        phone: participant.phone,
        isPresent: participant.isPresent,
        userId: participant.userId,
        connectionStatus: participant.connectionStatus,
        connectionRequestId: participant.connectionRequestId,
      ),
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


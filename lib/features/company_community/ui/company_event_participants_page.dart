import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/silent_refresh.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/photo_viewer.dart';
import '../../../shared/widgets/poster_image.dart';
import '../models/event_participant_summary.dart';
import '../services/company_community_service.dart';
import '../widgets/participant_list_widgets.dart';
import 'event_invitations_tab.dart';
import 'event_qr_models_page.dart';

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
  // Affiche de l'événement, entière, en tête de la liste des participants.
  final String? imageUrl;
  // Un événement terminé ne doit plus pouvoir être partagé — inutile
  // d'inviter à s'inscrire à quelque chose qui n'a plus lieu — cf. bouton
  // de partage plus bas, masqué dans ce cas.
  final bool eventHasEnded;
  // Onglets « Participants » / « Invitations » — mêmes comptes que ceux qui
  // ouvrent cette page (User.canAccessCompanyCommunity). Sans eux, la page
  // reste exactement l'écran des participants d'avant.
  final bool showInvitations;
  final bool canManageParticipants;

  const CompanyEventParticipantsPage({
    super.key,
    required this.eventId,
    required this.eventName,
    this.publicUrl,
    this.imageUrl,
    this.eventHasEnded = false,
    this.showInvitations = false,
    this.canManageParticipants = false,
  });

  @override
  State<CompanyEventParticipantsPage> createState() =>
      _CompanyEventParticipantsPageState();
}

class _CompanyEventParticipantsPageState
    extends State<CompanyEventParticipantsPage>
    with SingleTickerProviderStateMixin, SilentRefreshMixin {
  final _service = CompanyCommunityService();
  // Créé seulement quand les onglets sont affichés (showInvitations).
  TabController? _tabs;
  // L'onglet Invitations n'est chargé qu'à sa première ouverture.
  bool _invitationsOpened = false;
  List<EventParticipantSummary> _participants = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _error;
  int? _removingParticipantId;

  @override
  void initState() {
    super.initState();
    if (widget.showInvitations) {
      _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
    }
    _load();
    startSilentRefresh();
  }

  /// Onglet Participants à l'écran (l'onglet Invitations a le sien).
  @override
  bool get silentRefreshVisible =>
      (_tabs?.index ?? 0) == 0 && super.silentRefreshVisible;

  /// Présences du jour J en direct : liste remplacée sur place, sans loader.
  @override
  Future<void> silentRefresh() async {
    if (_isLoading || _error != null) return;
    final result = await _service.fetchParticipants(widget.eventId);
    if (!mounted) return;
    setState(() {
      _participants = result.participants;
      _stats = result.stats;
    });
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final tabs = _tabs!;
    if (tabs.indexIsChanging) return;
    setState(() => _invitationsOpened |= tabs.index == 1);
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
        // QR de check-in en 5 modèles (impression, affichage à l'accueil).
        if (widget.showInvitations && !widget.eventHasEnded)
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: "QR de l'événement",
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EventQrModelsPage(eventId: widget.eventId, eventName: widget.eventName),
            )),
          ),
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
      bottom: widget.showInvitations ? _buildTabs() : null,
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
            child: widget.showInvitations
                ? IndexedStack(
                    index: _tabs!.index,
                    children: [
                      _buildBody(colors, topPadding),
                      if (_invitationsOpened)
                        EventInvitationsTab(
                          eventId: widget.eventId,
                          topPadding: topPadding,
                          visible: _tabs!.index == 1,
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  )
                : _buildBody(colors, topPadding),
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

  /// Même pilule « segmented control » qu'Explorer et JobMatch.
  PreferredSizeWidget _buildTabs() {
    final colors = Theme.of(context).colorScheme;
    return PreferredSize(
      preferredSize: const Size.fromHeight(58),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(6),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            splashBorderRadius: BorderRadius.circular(6),
            labelColor: Colors.white,
            unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Participants'), Tab(text: 'Invitations')],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colors, double topPadding) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const AppLoader(label: 'Chargement des participants...'),
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

    return RefreshIndicator(
      edgeOffset: topPadding,
      onRefresh: silentRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 32),
        children: [
          if (widget.imageUrl != null) ...[
            PosterImage(imageUrl: widget.imageUrl!, onTap: () => PhotoViewer.show(context, widget.imageUrl!)),
            const SizedBox(height: 16),
          ],
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
                eventHasEnded: widget.eventHasEnded,
                onTap: () => _openParticipantSheet(p),
                onTogglePresence: widget.eventHasEnded
                    ? () => _toggleParticipantPresence(p)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme colors) {
    final registered = _stats['registered'] as int? ?? 0;
    final present = _stats['present'] as int? ?? 0;
    final walkIns = _stats['walk_ins'] as int? ?? 0;
    final notPresent = _stats['not_present'] as int? ?? (registered - present);
    // « Absents » seulement après la fin ; avant, « Pas encore arrivés ».
    final ended = _stats['event_ended'] as bool? ?? widget.eventHasEnded;

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
                    label: ended ? 'Absents' : 'Pas encore arrivés',
                    value: notPresent,
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

  /// Correction manuelle présent/absent — uniquement une fois l'événement
  /// terminé (widget.eventHasEnded), le backend refusant sinon (422, cf.
  /// EventController::updateParticipantPresence()) : avant la fin, le scan
  /// jour J reste la seule source de vérité. Optimiste, avec retour en
  /// arrière si le serveur refuse — même logique que côté highlight
  /// d'événement (cf. EventHighlightDetailPage._toggleAttendeePresence()).
  Future<void> _toggleParticipantPresence(EventParticipantSummary p) async {
    final next = !p.isPresent;

    setState(() {
      _participants = _participants
          .map((x) => x.id == p.id ? x.copyWith(isPresent: next) : x)
          .toList();
    });

    try {
      await _service.setParticipantPresence(widget.eventId, p.id, next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _participants = _participants
            .map((x) => x.id == p.id ? x.copyWith(isPresent: !next) : x)
            .toList();
      });
      FeedbackOverlay.showError(
        context,
        title: 'Erreur',
        subtitle: 'Impossible de mettre à jour la présence.',
      );
    }
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

  /// Fiche légère (identité + coordonnées, ce service n'étant atteignable
  /// que par un collaborateur/admin + connexion) — remonté côté produit :
  /// la carte publique complète (stats, réseaux sociaux, expériences)
  /// était "trop chargée" pour ce simple aperçu depuis la liste des
  /// participants d'un événement.
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
        eventHasEnded: widget.eventHasEnded,
        onBadge: (format) => _shareBadge(participant, format),
        userId: participant.userId,
        connectionStatus: participant.connectionStatus,
        connectionRequestId: participant.connectionRequestId,
        onDelete: widget.canManageParticipants
            ? () {
                Navigator.of(context).pop();
                _removeParticipant(participant);
              }
            : null,
      ),
    );
  }

  Future<void> _removeParticipant(EventParticipantSummary participant) async {
    if (_removingParticipantId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer ce participant ?'),
        content: Text(
          '${participant.displayName} ne figurera plus dans cet événement. Son compte KART ne sera pas supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingParticipantId = participant.id);
    try {
      await _service.removeParticipant(widget.eventId, participant.id);
      if (!mounted) return;
      try {
        final result = await _service.fetchParticipants(widget.eventId);
        if (!mounted) return;
        setState(() {
          _participants = result.participants;
          _stats = result.stats;
        });
      } on DioException catch (error) {
        if (!mounted) return;
        setState(() {
          _participants =
              _participants.where((item) => item.id != participant.id).toList();
        });
        FeedbackOverlay.showError(
          context,
          title: 'Liste non actualisée',
          subtitle: _messageFor(error),
        );
        return;
      }
      FeedbackOverlay.showSuccess(
        context,
        title: 'Participation retirée',
        subtitle: 'Le compte KART de ${participant.displayName} est conservé.',
      );
    } on DioException catch (error) {
      if (!mounted) return;
      FeedbackOverlay.showError(
        context,
        title: 'Suppression impossible',
        subtitle: _messageFor(error),
      );
    } finally {
      if (mounted) setState(() => _removingParticipantId = null);
    }
  }

  /// Badge d'un participant : PNG 300 dpi ou PDF au format exact, ouvert
  /// dans la feuille de partage (Enregistrer l'image, WhatsApp, Imprimer…).
  Future<void> _shareBadge(EventParticipantSummary participant, String format) async {
    try {
      final bytes = await _service.fetchParticipantBadge(widget.eventId, participant.id, format);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/badge-${widget.eventId}-${participant.id}.$format');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: format == 'pdf' ? 'application/pdf' : 'image/png')],
        subject: 'Badge · ${participant.displayName}',
      ));
    } catch (_) {
      if (!mounted) return;
      FeedbackOverlay.showError(context,
          title: 'Badge indisponible', subtitle: "Le badge n'a pas pu être préparé. Réessayez dans un instant.");
    }
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
      height: 96,
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
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11, color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}

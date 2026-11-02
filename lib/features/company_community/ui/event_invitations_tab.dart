import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/filter_pill_chip.dart';
import '../../../shared/utils/silent_refresh.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../models/event_invitation.dart';
import '../services/device_contacts.dart';
import '../services/event_invitations_service.dart';
import '../widgets/invitation_sheets.dart';
import '../widgets/invitation_widgets.dart';
import 'invitation_contacts_flow.dart';
import 'invitation_sender.dart';

/// Onglet « Invitations » d'un événement : compteurs, envoi au suivant,
/// liste filtrable, ajout (à la main ou depuis les contacts), envoi par
/// WhatsApp ou partage de l'image. Le message se personnalise sur le site.
class EventInvitationsTab extends StatefulWidget {
  final int eventId;
  final double topPadding;
  /// Onglet affiché (il vit dans un IndexedStack) : l'actualisation
  /// silencieuse ne tourne que lorsqu'il est à l'écran.
  final bool visible;
  final EventInvitationsService? service;
  final InvitationSender? sender;
  final DeviceContactsSource? contacts;

  const EventInvitationsTab({
    super.key,
    required this.eventId,
    required this.topPadding,
    this.visible = true,
    this.service,
    this.sender,
    this.contacts,
  });

  @override
  State<EventInvitationsTab> createState() => _EventInvitationsTabState();
}

class _EventInvitationsTabState extends State<EventInvitationsTab> with SilentRefreshMixin {
  late final EventInvitationsService _service = widget.service ?? EventInvitationsService();
  late final InvitationSender _sender =
      widget.sender ?? InvitationSender(service: _service, eventId: widget.eventId);
  final _search = TextEditingController();
  Timer? _searchDebounce;

  List<EventInvitation> _items = [];
  InvitationCounts _counts = const InvitationCounts();
  List<String> _categories = [];
  int _page = 1;
  int _lastPage = 1;
  InvitationStatus? _status;
  String? _category;
  EventInvitation? _next;
  int _remaining = 0;

  bool _loading = true;
  bool _loadingMore = false;
  /// Erreur du premier chargement : écran d'erreur.
  String? _error;
  /// Erreur après un chargement réussi : bandeau, liste et filtres gardés.
  String? _staleError;
  bool _loadedOnce = false;
  bool _eventEnded = false;
  /// Seule la dernière requête lancée s'applique (changements de filtre
  /// rapides : une réponse lente ne doit pas écraser la liste affichée) ;
  /// la précédente est annulée.
  int _requestSeq = 0;
  CancelToken? _inflight;
  /// Première page déjà reçue pour chaque filtre (statut, catégorie,
  /// recherche) : un filtre déjà vu s'affiche tout de suite.
  final Map<String, InvitationPage> _cache = {};
  /// Toutes les invitations déjà reçues : filtrage local immédiat d'un
  /// filtre jamais vu, en attendant la réponse du serveur.
  final Map<int, EventInvitation> _known = {};
  int? _busyId;
  bool _sendingNext = false;

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);
    startSilentRefresh();
  }

  @override
  bool get silentRefreshVisible => widget.visible && super.silentRefreshVisible;

  /// Pas pendant le défilement infini : remplacer la page 1 ferait sauter
  /// la liste. Le tirer-pour-actualiser reste possible.
  @override
  Future<void> silentRefresh() async {
    if (_page > 1 || _loadingMore || _busyId != null || _sendingNext) return;
    await _refresh(silent: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String get _filterKey => [_status?.api ?? '', _category ?? '', _search.text.trim().toLowerCase()].join('|');

  /// Affichage immédiat d'un filtre : page en cache, sinon filtrage local
  /// des invitations déjà reçues. La réponse du serveur suit (_refresh).
  void _applyLocal() {
    final cached = _cache[_filterKey];
    setState(() {
      if (cached != null) {
        _items = cached.items;
        _counts = cached.counts;
        _page = cached.currentPage;
        _lastPage = cached.lastPage;
      } else {
        _items = _known.values
            .where((i) => i.matches(status: _status, category: _category, query: _search.text))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _page = 1;
        _lastPage = 1;
      }
    });
  }

  /// Après un envoi, un ajout ou une suppression : les pages en cache ne
  /// sont plus à jour.
  Future<void> _reload() {
    _cache.clear();
    return _refresh();
  }

  Future<void> _refresh({bool initial = false, bool silent = false}) async {
    final seq = ++_requestSeq;
    _inflight?.cancel();
    final token = _inflight = CancelToken();
    final key = _filterKey;
    if (initial) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.list(widget.eventId,
            status: _status, category: _category, query: _search.text, page: 1, cancelToken: token),
        _service.next(widget.eventId),
      ]);
      if (!mounted || seq != _requestSeq) return;
      final page = results[0] as InvitationPage;
      final next = results[1] as ({EventInvitation? next, int remaining});
      _cache[key] = page;
      for (final invitation in page.items) {
        _known[invitation.id] = invitation;
      }
      setState(() {
        _items = page.items;
        _counts = page.counts;
        _categories = page.categories;
        _page = page.currentPage;
        _lastPage = page.lastPage;
        _next = next.next;
        _remaining = next.remaining;
        _eventEnded = page.eventEnded;
        _error = null;
        _staleError = null;
        _loadedOnce = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      // Requête remplacée par un filtre plus récent : rien à signaler.
      if (e is DioException && CancelToken.isCancel(e)) return;
      final message = EventInvitationsService.errorMessage(e,
          fallback: 'Impossible de charger les invitations.');
      setState(() {
        _loading = false;
        if (!_loadedOnce) {
          _error = message;
        } else if (!silent) {
          _staleError = message;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.list(widget.eventId,
          status: _status, category: _category, query: _search.text, page: _page + 1);
      if (!mounted) return;
      for (final invitation in page.items) {
        _known[invitation.id] = invitation;
      }
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.currentPage;
        _lastPage = page.lastPage;
      });
    } catch (e) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: 'Erreur', subtitle: EventInvitationsService.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearch(String _) {
    // Liste filtrée à chaque lettre ; le serveur est interrogé une fois la
    // saisie posée.
    _applyLocal();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _refresh);
  }

  void _setStatus(InvitationStatus? status) {
    _status = status;
    _applyLocal();
    _refresh();
  }

  void _setCategory(String? category) {
    _category = category;
    _applyLocal();
    _refresh();
  }

  Future<void> _sendWhatsApp(EventInvitation invitation) async {
    setState(() => _busyId = invitation.id);
    await _sender.sendWhatsApp(context, invitation);
    if (!mounted) return;
    setState(() => _busyId = null);
    _reload();
  }

  Future<void> _sendNext() async {
    final next = _next;
    if (next == null || _sendingNext) return;
    setState(() => _sendingNext = true);
    await _sender.sendWhatsApp(context, next);
    if (!mounted) return;
    setState(() => _sendingNext = false);
    _reload();
  }

  Future<void> _share(EventInvitation invitation) async {
    setState(() => _busyId = invitation.id);
    await _sender.shareInvitation(context, invitation);
    if (!mounted) return;
    setState(() => _busyId = null);
    _reload();
  }

  Future<void> _edit(EventInvitation? invitation) async {
    final changed = await showInvitationFormSheet(context,
        service: _service, eventId: widget.eventId, invitation: invitation);
    if (changed && mounted) _reload();
  }

  Future<void> _delete(EventInvitation invitation) async {
    final confirmed = await GlassDialog.confirm(
      context,
      title: 'Retirer de la liste ?',
      message: "${invitation.name} ne fera plus partie des invités. Son lien d'invitation ne fonctionnera plus.",
      confirmLabel: 'Retirer',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.delete(widget.eventId, invitation.id);
      if (!mounted) return;
      FeedbackOverlay.showSuccess(context,
          title: 'Invité retiré', subtitle: '${invitation.name} a été retiré(e) de la liste.');
      _known.remove(invitation.id);
      _reload();
    } catch (e) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: 'Erreur', subtitle: EventInvitationsService.errorMessage(e));
      }
    }
  }

  Future<void> _addFromContacts() async {
    final report = await openInvitationContactsFlow(context,
        service: _service, eventId: widget.eventId, source: widget.contacts);
    if (report == null || !mounted) return;
    await _reload();
    if (mounted) await showInvitationReportSheet(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.only(top: widget.topPadding),
        child: const AppLoader(label: 'Chargement des invitations...'),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.only(top: widget.topPadding),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => _refresh(initial: true), child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    final hasFilters = _status != null || _category != null || _search.text.trim().isNotEmpty;

    return RefreshIndicator(
      edgeOffset: widget.topPadding,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) _loadMore();
          return false;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, widget.topPadding + 12, 16, 32),
          children: [
            if (_staleError != null) ...[
              _buildStaleErrorBanner(colors),
              const SizedBox(height: 12),
            ],
            _buildCounts(colors),
            const SizedBox(height: 16),
            if (_eventEnded)
              _buildEndedBanner(colors)
            else ...[
              _buildNextButton(colors),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InvitationOutlineButton(
                      label: 'Ajouter',
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () => _edit(null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InvitationOutlineButton(
                      label: 'Mes contacts',
                      icon: Icons.contacts_outlined,
                      onTap: _addFromContacts,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            AppSearchBar(
              controller: _search,
              hintText: 'Rechercher un invité…',
              onChanged: _onSearch,
            ),
            const SizedBox(height: 10),
            _buildFilters(),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Text(
                      hasFilters ? 'Aucun invité ne correspond' : 'Aucun invité pour le moment',
                      style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface),
                    ),
                    if (!hasFilters) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ajoutez vos invités à la main ou depuis vos contacts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ],
                ),
              )
            else
              for (final invitation in _items)
                InvitationListTile(
                  invitation: invitation,
                  busy: _busyId == invitation.id,
                  onSend: !_eventEnded && (invitation.status == InvitationStatus.pending || invitation.needsReminder)
                      ? () => _sendWhatsApp(invitation)
                      : null,
                  onResend: _eventEnded ? null : () => _sendWhatsApp(invitation),
                  onShare: () => _share(invitation),
                  onEdit: () => _edit(invitation),
                  onDelete: () => _delete(invitation),
                ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            const SizedBox(height: 12),
            Text(
              'Le message des invitations se personnalise depuis le site, dans le détail de l\'événement.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: colors.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaleErrorBanner(ColorScheme colors) {
    return Material(
      color: colors.error.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: colors.error),
            const SizedBox(width: 10),
            Expanded(child: Text(_staleError!, style: TextStyle(fontSize: 13, color: colors.onSurface))),
            TextButton(onPressed: _refresh, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildEndedBanner(ColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Cet événement est terminé : la liste reste consultable, mais plus aucune invitation ne peut être ajoutée ni envoyée.',
        style: TextStyle(fontSize: 13, height: 1.35, color: colors.onSurface),
      ),
    );
  }

  Widget _buildCounts(ColorScheme colors) {
    final brightness = Theme.of(context).brightness;
    Color status(InvitationStatus s) => invitationStatusColor(s, brightness);
    final tiles = [
      ('Invités', _counts.invited, colors.onSurface),
      ('Envoyées', _counts.sent, status(InvitationStatus.sent)),
      ('Ouvertes', _counts.opened, status(InvitationStatus.opened)),
      ('Confirmées', _counts.confirmed, status(InvitationStatus.confirmed)),
      ('Déclinées', _counts.declined, status(InvitationStatus.declined)),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: InvitationCountTile(label: tiles[i].$1, value: tiles[i].$2, color: tiles[i].$3)),
        ],
      ],
    );
  }

  Widget _buildNextButton(ColorScheme colors) {
    final enabled = _next != null && !_sendingNext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: whatsappGreen,
              foregroundColor: const Color(0xFF072E16),
              disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.08),
              disabledForegroundColor: colors.onSurface.withValues(alpha: 0.4),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: enabled ? _sendNext : null,
            icon: _sendingNext
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF072E16)))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text('Envoyer au suivant ($_remaining)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _next != null ? 'Prochain : ${_next!.name}' : 'Toutes les invitations ont été envoyées.',
            style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final statuses = <(String, InvitationStatus?)>[
      ('Toutes', null),
      for (final s in InvitationStatus.values) (s.label, s),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (label, status) in statuses)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterPillChip(
                    label: label,
                    active: _status == status,
                    onTap: () => _setStatus(status),
                  ),
                ),
            ],
          ),
        ),
        if (_categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterPillChip(
                    label: 'Toutes catégories',
                    icon: Icons.sell_outlined,
                    active: _category == null,
                    onTap: () => _setCategory(null),
                  ),
                ),
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterPillChip(
                      label: category,
                      active: _category == category,
                      onTap: () => _setCategory(category),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

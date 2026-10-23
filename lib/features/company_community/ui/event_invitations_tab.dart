import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/filter_pill_chip.dart';
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
  final EventInvitationsService? service;
  final InvitationSender? sender;
  final DeviceContactsSource? contacts;

  const EventInvitationsTab({
    super.key,
    required this.eventId,
    required this.topPadding,
    this.service,
    this.sender,
    this.contacts,
  });

  @override
  State<EventInvitationsTab> createState() => _EventInvitationsTabState();
}

class _EventInvitationsTabState extends State<EventInvitationsTab> {
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
  String? _error;
  int? _busyId;
  bool _sendingNext = false;

  @override
  void initState() {
    super.initState();
    _refresh(initial: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool initial = false}) async {
    if (initial) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.list(widget.eventId,
            status: _status, category: _category, query: _search.text, page: 1),
        _service.next(widget.eventId),
      ]);
      if (!mounted) return;
      final page = results[0] as InvitationPage;
      final next = results[1] as ({EventInvitation? next, int remaining});
      setState(() {
        _items = page.items;
        _counts = page.counts;
        _categories = page.categories;
        _page = page.currentPage;
        _lastPage = page.lastPage;
        _next = next.next;
        _remaining = next.remaining;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = EventInvitationsService.errorMessage(e,
            fallback: 'Impossible de charger les invitations.');
        _loading = false;
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _refresh);
  }

  void _setStatus(InvitationStatus? status) {
    setState(() => _status = status);
    _refresh();
  }

  void _setCategory(String? category) {
    setState(() => _category = category);
    _refresh();
  }

  Future<void> _sendWhatsApp(EventInvitation invitation) async {
    setState(() => _busyId = invitation.id);
    await _sender.sendWhatsApp(context, invitation);
    if (!mounted) return;
    setState(() => _busyId = null);
    _refresh();
  }

  Future<void> _sendNext() async {
    final next = _next;
    if (next == null || _sendingNext) return;
    setState(() => _sendingNext = true);
    await _sender.sendWhatsApp(context, next);
    if (!mounted) return;
    setState(() => _sendingNext = false);
    _refresh();
  }

  Future<void> _share(EventInvitation invitation) async {
    setState(() => _busyId = invitation.id);
    await _sender.shareInvitation(context, invitation);
    if (!mounted) return;
    setState(() => _busyId = null);
    _refresh();
  }

  Future<void> _edit(EventInvitation? invitation) async {
    final changed = await showInvitationFormSheet(context,
        service: _service, eventId: widget.eventId, invitation: invitation);
    if (changed && mounted) _refresh();
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
      _refresh();
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
    await _refresh();
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
            _buildCounts(colors),
            const SizedBox(height: 16),
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
                  onSend: invitation.status == InvitationStatus.pending || invitation.needsReminder
                      ? () => _sendWhatsApp(invitation)
                      : null,
                  onResend: () => _sendWhatsApp(invitation),
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

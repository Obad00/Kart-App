import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../models/event_invitation.dart';
import '../services/device_contacts.dart';
import '../services/event_invitations_service.dart';
import '../utils/phone_display.dart';
import '../widgets/invitation_sheets.dart';
import '../widgets/invitation_widgets.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Limite de la route batch (500 invités par envoi).
const _maxPerBatch = 500;

/// « Ajouter depuis mes contacts ». Renvoie le rapport d'ajout, ou null si
/// rien n'a été ajouté (abandon). La permission n'est demandée qu'ici, au
/// clic, après l'écran d'explication.
Future<InvitationReport?> openInvitationContactsFlow(
  BuildContext context, {
  required EventInvitationsService service,
  required int eventId,
  DeviceContactsSource? source,
}) async {
  final contacts = source ?? PlatformDeviceContacts();
  final ios = defaultTargetPlatform == TargetPlatform.iOS;

  Widget first = InvitationContactsIntroPage(service: service, eventId: eventId, source: contacts);
  if (ios) {
    final access = await contacts.check();
    // Accès déjà donné : pas d'explication à répéter, directement la liste.
    if (access == ContactsAccess.full || access == ContactsAccess.limited) {
      first = InvitationContactsPickerPage(
          service: service, eventId: eventId, source: contacts, limited: access == ContactsAccess.limited);
    }
  }
  if (!context.mounted) return null;
  return Navigator.push<InvitationReport>(context, MaterialPageRoute(builder: (_) => first));
}

/// Un contact choisi, avec le numéro retenu (le mobile par défaut).
class _Choice {
  final DeviceContact contact;
  int phoneIndex;

  _Choice(this.contact) : phoneIndex = contact.defaultPhoneIndex;

  DeviceContactPhone get phone => contact.phones[phoneIndex];
}

// ---------------------------------------------------------------------------
// Explication
// ---------------------------------------------------------------------------

class InvitationContactsIntroPage extends StatefulWidget {
  final EventInvitationsService service;
  final int eventId;
  final DeviceContactsSource source;

  /// Forcé dans les tests ; sinon lu sur la plateforme.
  final bool? ios;

  const InvitationContactsIntroPage({
    super.key,
    required this.service,
    required this.eventId,
    required this.source,
    this.ios,
  });

  @override
  State<InvitationContactsIntroPage> createState() => _InvitationContactsIntroPageState();
}

class _InvitationContactsIntroPageState extends State<InvitationContactsIntroPage> {
  bool _busy = false;
  bool _denied = false;

  bool get _ios => widget.ios ?? defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      if (_ios) {
        final access = await widget.source.request();
        if (!mounted) return;
        if (access == ContactsAccess.full || access == ContactsAccess.limited) {
          await _open(InvitationContactsPickerPage(
            service: widget.service,
            eventId: widget.eventId,
            source: widget.source,
            limited: access == ContactsAccess.limited,
          ));
        } else {
          setState(() => _denied = true);
        }
      } else {
        final picked = await pickContactsOneByOne(context, widget.source);
        if (picked.isNotEmpty && mounted) {
          await _open(InvitationContactsReviewPage(
            service: widget.service,
            eventId: widget.eventId,
            source: widget.source,
            initial: picked,
            ios: false,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Accès refusé (iOS) : sélecteur natif multiple, sans permission.
  Future<void> _nativePicker() async {
    setState(() => _busy = true);
    try {
      final picked = await widget.source.pickMultipleNative();
      if (picked.isNotEmpty && mounted) {
        await _open(InvitationContactsReviewPage(
          service: widget.service,
          eventId: widget.eventId,
          source: widget.source,
          initial: picked,
          ios: true,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Widget page) async {
    final report = await Navigator.push<InvitationReport>(context, MaterialPageRoute(builder: (_) => page));
    if (report != null && mounted) Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = const GlassAppBar(title: Text('Depuis mes contacts'));
    final topPadding = glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final points = _ios
        ? const [
            (Icons.phone_iphone_rounded, 'Vos contacts sont lus sur ce téléphone, pour que vous choisissiez qui inviter.'),
            (Icons.check_circle_outline_rounded, 'Seuls les contacts que vous cochez sont envoyés à KART : nom et numéro.'),
            (Icons.lock_outline_rounded, "Rien d'autre n'est transmis ni stocké."),
          ]
        : const [
            (Icons.contacts_outlined, 'Choisissez vos invités dans vos contacts.'),
            (Icons.check_circle_outline_rounded, 'Seuls les contacts que vous sélectionnez sont envoyés à KART.'),
            (Icons.replay_rounded, 'Le sélecteur se rouvre après chaque contact : appuyez sur Retour quand vous avez fini.'),
          ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, bottomPadding + 24),
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _themeBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.contacts_rounded, color: _themeBlue, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _denied ? "L'accès aux contacts est refusé" : 'Invitez vos contacts',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: colors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                _denied
                    ? 'Vous pouvez quand même choisir vos invités avec le sélecteur du téléphone, sans donner accès à vos contacts.'
                    : "Ajoutez en une fois les personnes à inviter, puis envoyez-leur l'invitation sur WhatsApp.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: colors.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 28),
              if (!_denied)
                for (final (icon, text) in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 22, color: _themeBlue),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(text,
                              style: TextStyle(fontSize: 14.5, height: 1.4, color: colors.onSurface)),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 16),
              if (_denied) ...[
                InvitationPrimaryButton(
                  label: 'Choisir avec le sélecteur du téléphone',
                  loading: _busy,
                  onTap: _nativePicker,
                ),
                const SizedBox(height: 12),
                InvitationOutlineButton(
                  label: 'Autoriser dans les Réglages',
                  icon: Icons.settings_outlined,
                  onTap: widget.source.openSettings,
                ),
              ] else
                InvitationPrimaryButton(
                  label: _ios ? 'Continuer' : 'Choisir mes invités',
                  loading: _busy,
                  onTap: _continue,
                ),
            ],
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
}

/// Android : le sélecteur système se rouvre après chaque contact choisi ;
/// Retour termine. Les contacts déjà choisis ne sont pas ajoutés deux fois.
Future<List<DeviceContact>> pickContactsOneByOne(
  BuildContext context,
  DeviceContactsSource source, {
  Set<String> alreadyChosen = const {},
}) async {
  final picked = <DeviceContact>[];
  final seen = {...alreadyChosen};
  while (true) {
    DeviceContact? contact;
    try {
      contact = await source.pickOneNative();
    } on PlatformException catch (e) {
      if (context.mounted) {
        FeedbackOverlay.showError(context,
            title: 'Contacts indisponibles', subtitle: e.message ?? "Le sélecteur n'a pas pu s'ouvrir.");
      }
      break;
    }
    if (contact == null) break;
    if (seen.add(contact.id)) picked.add(contact);
    if (seen.length >= _maxPerBatch) break;
  }
  return picked;
}

// ---------------------------------------------------------------------------
// iOS : liste des contacts, sélection multiple
// ---------------------------------------------------------------------------

class InvitationContactsPickerPage extends StatefulWidget {
  final EventInvitationsService service;
  final int eventId;
  final DeviceContactsSource source;
  final bool limited;

  const InvitationContactsPickerPage({
    super.key,
    required this.service,
    required this.eventId,
    required this.source,
    required this.limited,
  });

  @override
  State<InvitationContactsPickerPage> createState() => _InvitationContactsPickerPageState();
}

class _InvitationContactsPickerPageState extends State<InvitationContactsPickerPage> {
  final _search = TextEditingController();
  final _category = TextEditingController();
  List<DeviceContact> _contacts = [];
  final Map<String, _Choice> _selected = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<DeviceContact> contacts = [];
    try {
      contacts = await widget.source.readAll();
    } catch (_) {
      if (mounted) {
        FeedbackOverlay.showError(context,
            title: 'Contacts indisponibles', subtitle: 'La liste de vos contacts n\'a pas pu être lue.');
      }
    }
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  /// Accès limité : contacts hors de la sélection autorisée, via le
  /// sélecteur natif (sans élargir l'accès). Ils arrivent déjà cochés.
  Future<void> _pickOthers() async {
    final picked = await widget.source.pickMultipleNative();
    if (!mounted || picked.isEmpty) return;
    setState(() {
      for (final contact in picked) {
        if (!_contacts.any((c) => c.id == contact.id)) _contacts.insert(0, contact);
        _selected.putIfAbsent(contact.id, () => _Choice(contact));
      }
    });
  }

  List<DeviceContact> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(query) || c.phones.any((p) => p.number.contains(query)))
        .toList();
  }

  void _toggle(DeviceContact contact) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.remove(contact.id) == null) {
        if (_selected.length >= _maxPerBatch) {
          FeedbackOverlay.showInfo(context,
              title: 'Limite atteinte', subtitle: '$_maxPerBatch invités au plus par ajout.');
          return;
        }
        _selected[contact.id] = _Choice(contact);
      }
    });
  }

  Future<void> _submit() async {
    final report = await _sendBatch(
      context,
      service: widget.service,
      eventId: widget.eventId,
      choices: _selected.values.toList(),
      category: _category.text,
      onBusy: (busy) => setState(() => _submitting = busy),
    );
    if (report != null && mounted) Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = GlassAppBar(
      title: const Text('Mes contacts'),
      actions: [
        if (_selected.isNotEmpty)
          TextButton(
            onPressed: () => setState(_selected.clear),
            child: const Text('Tout décocher'),
          ),
      ],
    );
    final topPadding = glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;
    final visible = _visible;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          if (_loading)
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const AppLoader(label: 'Lecture de vos contacts...'),
            )
          else
            Column(
              children: [
                SizedBox(height: topPadding + 12),
                if (widget.limited)
                  _LimitedAccessBanner(onPickOthers: _pickOthers, onSettings: widget.source.openSettings),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AppSearchBar(
                    controller: _search,
                    hintText: 'Rechercher un nom, un numéro…',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        '${_selected.length} sélectionné${_selected.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: _themeBlue),
                      ),
                      const Spacer(),
                      Text(
                        '${_contacts.length} contact${_contacts.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyContacts(
                          limited: widget.limited,
                          searching: _search.text.trim().isNotEmpty,
                          onPickOthers: _pickOthers,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                          itemCount: visible.length,
                          itemBuilder: (_, index) {
                            final contact = visible[index];
                            final choice = _selected[contact.id];
                            return _ContactRow(
                              contact: contact,
                              selected: choice != null,
                              phoneIndex: choice?.phoneIndex ?? contact.defaultPhoneIndex,
                              onTap: () => _toggle(contact),
                              onChoosePhone: contact.phones.length > 1
                                  ? () => _choosePhone(context, contact, choice)
                                  : null,
                            );
                          },
                        ),
                ),
                _AddBar(
                  count: _selected.length,
                  category: _category,
                  busy: _submitting,
                  onSubmit: _submit,
                ),
              ],
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

  Future<void> _choosePhone(BuildContext context, DeviceContact contact, _Choice? choice) async {
    final index = await _showPhoneChoice(context, contact, choice?.phoneIndex ?? contact.defaultPhoneIndex);
    if (index == null || !mounted) return;
    setState(() {
      final current = _selected[contact.id] ?? _Choice(contact);
      current.phoneIndex = index;
      _selected[contact.id] = current;
    });
  }
}

class _LimitedAccessBanner extends StatelessWidget {
  final VoidCallback onPickOthers;
  final VoidCallback onSettings;

  const _LimitedAccessBanner({required this.onPickOthers, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: _themeBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _themeBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: _themeBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Vous avez autorisé KART à voir une partie de vos contacts seulement.',
                  style: TextStyle(fontSize: 13, height: 1.35, color: colors.onSurface),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(onPressed: onPickOthers, child: const Text("Choisir d'autres contacts")),
              TextButton(onPressed: onSettings, child: const Text("Modifier l'accès")),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyContacts extends StatelessWidget {
  final bool limited;
  final bool searching;
  final VoidCallback onPickOthers;

  const _EmptyContacts({required this.limited, required this.searching, required this.onPickOthers});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              searching ? 'Aucun contact ne correspond' : 'Aucun contact avec un numéro',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55)),
            ),
            if (limited && !searching) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onPickOthers, child: const Text("Choisir d'autres contacts")),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final DeviceContact contact;
  final bool selected;
  final int phoneIndex;
  final VoidCallback onTap;
  final VoidCallback? onChoosePhone;

  const _ContactRow({
    required this.contact,
    required this.selected,
    required this.phoneIndex,
    required this.onTap,
    this.onChoosePhone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final phone = contact.phones[phoneIndex];
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _Avatar(initials: contact.initials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  const SizedBox(height: 2),
                  _PhoneLine(phone: phone, multiple: onChoosePhone != null, onTap: onChoosePhone),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: _themeBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneLine extends StatelessWidget {
  final DeviceContactPhone phone;
  final bool multiple;
  final VoidCallback? onTap;

  const _PhoneLine({required this.phone, required this.multiple, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Text(
      '${phone.label} · ${formatPhoneForDisplay(phone.number)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.5, color: colors.onSurface.withValues(alpha: 0.55)),
    );
    if (!multiple) return text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded, size: 16, color: _themeBlue),
          const Text('Changer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _themeBlue)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;

  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _themeBlue.withValues(alpha: 0.12),
      child: Text(initials,
          style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 13, color: _themeBlue)),
    );
  }
}

/// Contact à plusieurs numéros : choix du numéro à inviter.
Future<int?> _showPhoneChoice(BuildContext context, DeviceContact contact, int current) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final colors = Theme.of(sheetContext).colorScheme;
      final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
      return GlassSheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset > 16 ? bottomInset : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text('Numéro de ${contact.name}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface)),
              const SizedBox(height: 4),
              Text("L'invitation part sur WhatsApp : choisissez le numéro qui l'utilise.",
                  style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.55))),
              const SizedBox(height: 12),
              for (var i = 0; i < contact.phones.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Navigator.pop(sheetContext, i),
                  title: Text(formatPhoneForDisplay(contact.phones[i].number),
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface)),
                  subtitle: Text(contact.phones[i].label),
                  trailing: i == current
                      ? const Icon(Icons.check_circle_rounded, color: _themeBlue)
                      : Icon(Icons.circle_outlined, color: colors.onSurface.withValues(alpha: 0.3)),
                ),
            ],
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Validation (Android, et repli iOS sur le sélecteur natif)
// ---------------------------------------------------------------------------

class InvitationContactsReviewPage extends StatefulWidget {
  final EventInvitationsService service;
  final int eventId;
  final DeviceContactsSource source;
  final List<DeviceContact> initial;
  final bool ios;

  const InvitationContactsReviewPage({
    super.key,
    required this.service,
    required this.eventId,
    required this.source,
    required this.initial,
    required this.ios,
  });

  @override
  State<InvitationContactsReviewPage> createState() => _InvitationContactsReviewPageState();
}

class _InvitationContactsReviewPageState extends State<InvitationContactsReviewPage> {
  final _category = TextEditingController();
  late final List<_Choice> _choices = widget.initial.map(_Choice.new).toList();
  bool _submitting = false;

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  Future<void> _addMore() async {
    final chosen = _choices.map((c) => c.contact.id).toSet();
    final List<DeviceContact> more;
    if (widget.ios) {
      more = await widget.source.pickMultipleNative();
    } else {
      more = await pickContactsOneByOne(context, widget.source, alreadyChosen: chosen);
    }
    if (!mounted) return;
    setState(() {
      for (final contact in more) {
        if (!chosen.contains(contact.id) && _choices.length < _maxPerBatch) {
          _choices.add(_Choice(contact));
          chosen.add(contact.id);
        }
      }
    });
  }

  Future<void> _submit() async {
    final report = await _sendBatch(
      context,
      service: widget.service,
      eventId: widget.eventId,
      choices: _choices,
      category: _category.text,
      onBusy: (busy) => setState(() => _submitting = busy),
    );
    if (report != null && mounted) Navigator.pop(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glassAppBar = const GlassAppBar(title: Text('Invités choisis'));
    final topPadding = glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(8, topPadding + 12, 8, 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        '${_choices.length} contact${_choices.length > 1 ? 's' : ''} sélectionné${_choices.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _themeBlue),
                      ),
                    ),
                    for (final choice in _choices)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            _Avatar(initials: choice.contact.initials),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(choice.contact.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600, color: colors.onSurface)),
                                  const SizedBox(height: 2),
                                  _PhoneLine(
                                    phone: choice.phone,
                                    multiple: choice.contact.phones.length > 1,
                                    onTap: () async {
                                      final index = await _showPhoneChoice(context, choice.contact, choice.phoneIndex);
                                      if (index != null && mounted) setState(() => choice.phoneIndex = index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Retirer',
                              icon: Icon(Icons.close_rounded, color: colors.onSurface.withValues(alpha: 0.5)),
                              onPressed: () => setState(() => _choices.remove(choice)),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: InvitationOutlineButton(
                        label: widget.ios ? "Choisir d'autres contacts" : 'Ajouter un autre contact',
                        icon: Icons.person_add_alt_1_outlined,
                        onTap: _addMore,
                      ),
                    ),
                  ],
                ),
              ),
              _AddBar(count: _choices.length, category: _category, busy: _submitting, onSubmit: _submit),
            ],
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
}

/// Barre du bas : catégorie commune facultative + « Ajouter N invités ».
class _AddBar extends StatelessWidget {
  final int count;
  final TextEditingController category;
  final bool busy;
  final VoidCallback onSubmit;

  const _AddBar({required this.count, required this.category, required this.busy, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return GlassSheet(
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, (bottomInset > 12 ? bottomInset : 12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: category,
              style: TextStyle(color: colors.onSurface, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Catégorie pour tous (facultatif) : VIP, Exposant…',
                hintStyle: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.45)),
                prefixIcon: Icon(Icons.sell_outlined, size: 18, color: colors.onSurface.withValues(alpha: 0.5)),
                filled: true,
                fillColor: colors.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _themeBlue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InvitationPrimaryButton(
              label: count == 0
                  ? 'Ajouter des invités'
                  : 'Ajouter $count invité${count > 1 ? 's' : ''}',
              loading: busy,
              onTap: count == 0 ? null : onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Une seule requête (route batch) pour toute la sélection.
Future<InvitationReport?> _sendBatch(
  BuildContext context, {
  required EventInvitationsService service,
  required int eventId,
  required List<_Choice> choices,
  required String category,
  required void Function(bool busy) onBusy,
}) async {
  if (choices.isEmpty) return null;
  onBusy(true);
  try {
    final report = await service.batch(
      eventId,
      [for (final c in choices) (name: c.contact.name, phone: c.phone.number)],
      category: category,
    );
    // « line » = position dans la liste envoyée (à partir de 1).
    return report.withPhones({
      for (var i = 0; i < choices.length; i++) i + 1: choices[i].phone.number,
    });
  } catch (e) {
    if (context.mounted) {
      FeedbackOverlay.showError(context,
          title: 'Ajout impossible', subtitle: EventInvitationsService.errorMessage(e));
    }
    return null;
  } finally {
    if (context.mounted) onBusy(false);
  }
}

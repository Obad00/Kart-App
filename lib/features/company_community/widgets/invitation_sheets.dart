import 'package:flutter/material.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../models/event_invitation.dart';
import '../services/event_invitations_service.dart';
import '../utils/phone_display.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Ajout ([invitation] null) ou modification d'un invité. Renvoie true si
/// la liste doit être rechargée (ajout, modification ou retrait).
Future<bool> showInvitationFormSheet(
  BuildContext context, {
  required EventInvitationsService service,
  required int eventId,
  EventInvitation? invitation,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvitationFormSheet(service: service, eventId: eventId, invitation: invitation),
  );
  return changed ?? false;
}

class _InvitationFormSheet extends StatefulWidget {
  final EventInvitationsService service;
  final int eventId;
  final EventInvitation? invitation;

  const _InvitationFormSheet({required this.service, required this.eventId, this.invitation});

  @override
  State<_InvitationFormSheet> createState() => _InvitationFormSheetState();
}

class _InvitationFormSheetState extends State<_InvitationFormSheet> {
  late final _name = TextEditingController(text: widget.invitation?.name);
  late final _phone = TextEditingController(text: widget.invitation?.phone);
  late final _email = TextEditingController(text: widget.invitation?.email);
  late final _category = TextEditingController(text: widget.invitation?.category);
  bool _saving = false;

  bool get _editing => widget.invitation != null;
  bool get _canSubmit => _name.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _category]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_canSubmit || _saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      if (_editing) {
        await widget.service.update(widget.eventId, widget.invitation!.id,
            name: _name.text.trim(), phone: _phone.text.trim(), email: _clean(_email), category: _clean(_category));
      } else {
        await widget.service.create(widget.eventId,
            name: _name.text.trim(), phone: _phone.text.trim(), email: _clean(_email), category: _clean(_category));
      }
      if (!mounted) return;
      FeedbackOverlay.showSuccess(
        context,
        title: _editing ? 'Invité modifié' : 'Invité ajouté',
        subtitle: _editing
            ? '${_name.text.trim()} a été mis(e) à jour.'
            : '${_name.text.trim()} est dans la liste, prêt(e) à recevoir son invitation.',
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackOverlay.showError(context,
          title: 'Erreur', subtitle: EventInvitationsService.errorMessage(e));
    }
  }

  Future<void> _delete() async {
    final invitation = widget.invitation!;
    final confirmed = await GlassDialog.confirm(
      context,
      title: 'Retirer de la liste ?',
      message: '${invitation.name} ne fera plus partie des invités. Son lien d\'invitation ne fonctionnera plus.',
      confirmLabel: 'Retirer',
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      await widget.service.delete(widget.eventId, invitation.id);
      if (!mounted) return;
      FeedbackOverlay.showSuccess(context,
          title: 'Invité retiré', subtitle: '${invitation.name} a été retiré(e) de la liste.');
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      FeedbackOverlay.showError(context,
          title: 'Erreur', subtitle: EventInvitationsService.errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassSheet(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text(
                _editing ? "Modifier l'invité" : 'Ajouter un invité',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Sans indicatif, le numéro est considéré comme sénégalais (+221).',
                style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 20),
              _field(_name, 'Nom complet', colors),
              const SizedBox(height: 12),
              _field(_phone, 'Téléphone WhatsApp', colors, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_email, 'Email (facultatif)', colors, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_category, 'Catégorie (facultatif) : VIP, Exposant…', colors),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _canSubmit && !_saving ? _submit : null,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_editing ? 'Enregistrer' : 'Ajouter',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _saving ? null : _delete,
                    child: const Text('Retirer de la liste',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Même champ que « Ajouter un contact » (fond léger, bordure bleue au focus).
  Widget _field(TextEditingController controller, String label, ColorScheme colors,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: colors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colors.onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _themeBlue, width: 1.5),
        ),
      ),
    );
  }
}

/// Rapport d'ajout depuis les contacts : ajoutés, déjà invités, invalides.
Future<void> showInvitationReportSheet(BuildContext context, InvitationReport report) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvitationReportSheet(report: report),
  );
}

class _InvitationReportSheet extends StatelessWidget {
  final InvitationReport report;

  const _InvitationReportSheet({required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
    final red = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GlassSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset > 24 ? bottomInset : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text(
              report.created > 0 ? 'Invités ajoutés' : 'Aucun invité ajouté',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _ReportCount(value: report.created, label: 'ajouté(s)', color: green)),
                const SizedBox(width: 10),
                Expanded(
                    child: _ReportCount(
                        value: report.duplicates, label: 'déjà invité(s)', color: colors.onSurface)),
                const SizedBox(width: 10),
                Expanded(
                    child: _ReportCount(
                        value: report.invalid.length,
                        label: 'numéro(s) invalide(s)',
                        color: report.invalid.isEmpty ? colors.onSurface : red)),
              ],
            ),
            if (report.invalid.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Non ajoutés',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: colors.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final row in report.invalid)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.name.isEmpty ? 'Sans nom' : row.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface)),
                                  if (report.phonesByLine[row.line]?.isNotEmpty ?? false)
                                    Text(formatPhoneForDisplay(report.phonesByLine[row.line]!),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(row.reason,
                                style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.55))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Terminé', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCount extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _ReportCount({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

/// Poignée des feuilles (même trait que « Ajouter un contact »).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

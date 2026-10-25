import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_menu.dart';
import '../models/event_invitation.dart';
import '../utils/phone_display.dart';

const _themeBlue = Color(0xFF3B82F6);
const whatsappGreen = Color(0xFF25D366);

/// Couleur d'un statut d'invitation, lisible en thème sombre comme clair.
Color invitationStatusColor(InvitationStatus status, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (status) {
    InvitationStatus.pending => dark ? const Color(0xFFB0B4BA) : const Color(0xFF5F6368),
    InvitationStatus.sent => dark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
    InvitationStatus.opened => dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
    InvitationStatus.confirmed => dark ? const Color(0xFF34D399) : const Color(0xFF047857),
    InvitationStatus.declined => dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
  };
}

/// Pastille de statut (même forme que « Présent » / « KART créé »).
class InvitationStatusPill extends StatelessWidget {
  final InvitationStatus status;

  const InvitationStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = invitationStatusColor(status, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Compteur de l'onglet (même tuile que les statistiques des participants).
class InvitationCountTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const InvitationCountTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.onSurface.withValues(alpha: 0.55)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une invitation dans la liste : identité, statut, action d'envoi, menu.
class InvitationListTile extends StatelessWidget {
  final EventInvitation invitation;
  final bool busy;
  /// Bouton visible : « Envoyer » (à envoyer) ou « Relancer » (48 h sans réponse).
  final VoidCallback? onSend;

  /// Renvoi depuis le menu, quand aucun bouton n'est affiché.
  final VoidCallback onResend;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InvitationListTile({
    super.key,
    required this.invitation,
    required this.onResend,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    this.onSend,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pending = invitation.status == InvitationStatus.pending;
    final subtitle = [formatPhoneForDisplay(invitation.phone), invitation.category]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _themeBlue.withValues(alpha: 0.12),
            child: Text(
              invitation.initials,
              style: const TextStyle(
                  fontFamily: 'Syne', fontWeight: FontWeight.w800, fontSize: 13, color: _themeBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    InvitationStatusPill(status: invitation.status),
                    if (invitation.needsReminder) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '48 h sans réponse',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MoreMenu(
                showWhatsApp: onSend == null,
                onWhatsApp: onResend,
                onShare: onShare,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
              if (onSend != null)
                _SendChip(
                  label: pending ? 'Envoyer' : 'Relancer',
                  filled: pending,
                  busy: busy,
                  onTap: onSend!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendChip extends StatelessWidget {
  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback onTap;

  const _SendChip({
    required this.label,
    required this.filled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineText = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
    return Material(
      color: filled ? whatsappGreen : whatsappGreen.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: filled ? BorderSide.none : BorderSide(color: whatsappGreen.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? const Color(0xFF072E16) : outlineText,
                  ),
                )
              else
                Icon(Icons.send_rounded, size: 14, color: filled ? const Color(0xFF072E16) : outlineText),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: filled ? const Color(0xFF072E16) : outlineText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final bool showWhatsApp;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MoreMenu({
    required this.showWhatsApp,
    required this.onWhatsApp,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Même menu verre que celui des contacts.
    return GlassMenuButton<String>(
      tooltip: "Plus d'options",
      onSelected: (value) => switch (value) {
        'whatsapp' => onWhatsApp(),
        'share' => onShare(),
        'edit' => onEdit(),
        'delete' => onDelete(),
        _ => null,
      },
      itemBuilder: (_) => [
        if (showWhatsApp)
          const GlassMenuItem(value: 'whatsapp', icon: Icons.send_rounded, title: 'Renvoyer sur WhatsApp'),
        const GlassMenuItem(value: 'share', icon: Icons.ios_share_rounded, title: "Partager l'invitation"),
        const GlassMenuItem(value: 'edit', icon: Icons.edit_outlined, title: 'Modifier'),
        const GlassMenuItem(
            value: 'delete', icon: Icons.delete_outline_rounded, title: 'Retirer de la liste', destructive: true),
      ],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(Icons.more_horiz_rounded, color: colors.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

/// Bouton principal du design system, dans les deux thèmes : blanc plein en
/// sombre, bleu KART (#002842) en clair. (AuthPrimaryButton est prévu pour
/// les écrans de connexion, toujours sombres.)
class InvitationPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const InvitationPrimaryButton({super.key, required this.label, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? Colors.white : const Color(0xFF002842);
    final foreground = dark ? Colors.black : Colors.white;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.08),
          disabledForegroundColor: colors.onSurface.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: loading ? () {} : onTap,
        child: loading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
            : Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

/// Bouton secondaire (contour), lisible dans les deux thèmes.
class InvitationOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const InvitationOutlineButton({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.onSurface.withValues(alpha: 0.18)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_sheet.dart';
import '../../explore/models/explore_user.dart' show ConnectionStatus;
import '../../explore/widgets/connect_action_button.dart';

const kParticipantThemeBlue = Color(0xFF3B82F6);

/// Ligne "avatar + nom + poste" partagée entre "Ma communauté" (liste des
/// inscrits d'un événement, avec présence) et la fiche de highlight d'un
/// événement (liste des autres participants, sans présence — remonté côté
/// produit : les deux listes avaient chacune leur propre design, ce qui
/// donnait l'impression de deux fonctionnalités différentes alors que
/// c'est la même donnée vue par deux publics différents).
class ParticipantListTile extends StatelessWidget {
  final String displayName;
  final String? subtitle;
  final VoidCallback? onTap;
  // null : ce badge n'a pas de sens pour cette liste (ex. highlight, où
  // tous les attendees ont déjà un compte KART et où la présence n'est
  // pas le sujet) — absent plutôt qu'affiché à moitié.
  final bool? isPresent;
  final bool? hasAccount;
  // Non-null uniquement quand l'événement est terminé ET que le viewer est
  // collaborateur/admin de l'entreprise organisatrice — remonté côté
  // produit : corriger manuellement une présence oubliée/erronée au scan,
  // mais seulement une fois le pointage jour J clos (cf.
  // EventController::updateParticipantPresence() côté backend, qui refuse
  // ce changement tant que l'événement est en cours).
  final VoidCallback? onTogglePresence;

  const ParticipantListTile({
    super.key,
    required this.displayName,
    this.subtitle,
    this.onTap,
    this.isPresent,
    this.hasAccount,
    this.onTogglePresence,
  });

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
              backgroundColor: kParticipantThemeBlue.withValues(alpha: 0.12),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontWeight: FontWeight.w800,
                  color: kParticipantThemeBlue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle?.isNotEmpty == true)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isPresent != null || hasAccount != null) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPresent != null)
                    ParticipantBadge(
                      label: isPresent! ? 'Présent' : 'Absent',
                      icon: isPresent!
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isPresent! ? Colors.green : Colors.grey,
                      onTap: onTogglePresence,
                    ),
                  if (isPresent != null && hasAccount != null)
                    const SizedBox(height: 4),
                  if (hasAccount != null)
                    ParticipantBadge(
                      label: hasAccount! ? 'KART créé' : 'Pas encore',
                      icon: hasAccount!
                          ? Icons.verified_rounded
                          : Icons.hourglass_empty_rounded,
                      color:
                          hasAccount! ? kParticipantThemeBlue : Colors.orange,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ParticipantBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  // Non-null uniquement pour le badge "Présent/Absent" d'un collaborateur
  // sur un événement terminé (cf. ParticipantListTile.onTogglePresence) —
  // le petit crayon signale que ce badge-là, contrairement aux autres, est
  // une action et pas qu'une information.
  final VoidCallback? onTap;

  const ParticipantBadge({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
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
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit_rounded, size: 10, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: badge,
    );
  }
}

/// Fiche ouverte au tap sur une ligne (même comportement que "voir tout"
/// dans Explorer) : coordonnées + mise en relation via le
/// ConnectActionButton partagé. [email]/[phone] restent `null` pour un
/// visiteur qui n'est pas collaborateur/admin de l'entreprise organisatrice
/// — c'est le backend qui ne les envoie pas dans ce cas (cf.
/// EventController::attendees()), jamais un simple masquage côté app.
class ParticipantDetailSheet extends StatelessWidget {
  final String displayName;
  final String? subtitle;
  final String? email;
  final String? phone;
  // null : la présence n'est pas pertinente pour cette liste (highlight).
  final bool? isPresent;
  final int? userId;
  final String connectionStatus;
  final int? connectionRequestId;
  // Après accepter/refuser une demande reçue depuis cette fiche — cf.
  // ConnectActionButton.onResolved. Optionnel : "Ma communauté" n'a pas
  // besoin de retirer la ligne (un événement doit montrer qui y participe
  // vraiment, contact ou non), contrairement à la fiche d'un highlight,
  // pensée comme une liste de découverte.
  final VoidCallback? onResolved;

  const ParticipantDetailSheet({
    super.key,
    required this.displayName,
    this.subtitle,
    this.email,
    this.phone,
    this.isPresent,
    this.userId,
    this.connectionStatus = 'none',
    this.connectionRequestId,
    this.onResolved,
  });

  ConnectionStatus get _status {
    switch (connectionStatus) {
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
                    backgroundColor:
                        kParticipantThemeBlue.withValues(alpha: 0.12),
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: kParticipantThemeBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        if (subtitle?.isNotEmpty == true)
                          Text(
                            subtitle!,
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
              if (email != null)
                _SheetInfoRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: email,
                ),
              if (phone != null)
                _SheetInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: phone,
                ),
              if (isPresent != null)
                _SheetInfoRow(
                  icon: Icons.event_available_outlined,
                  label: 'Présence',
                  value: isPresent! ? 'Présent' : 'Pas encore arrivé',
                ),
              if (email != null || phone != null || isPresent != null)
                const SizedBox(height: 18),
              // Pas de compte KART rattaché (walk-in pas encore inscrit) :
              // rien à quoi se connecter, on l'explique au lieu d'afficher
              // un bouton qui ne pourrait rien faire.
              if (userId == null)
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
                  userId: userId!,
                  userName: displayName,
                  initialStatus: _status,
                  initialRequestId: connectionRequestId,
                  compact: true,
                  onResolved: onResolved,
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

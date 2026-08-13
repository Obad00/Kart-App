import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/explore_user.dart';
import '../services/explore_service.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Bouton de mise en relation Explorer — autonome (pas besoin d'un
/// ExploreProvider ancestor), utilisé aussi bien dans la liste Explorer
/// que sur la carte publique d'un profil qui n'est pas encore un contact.
/// Gère lui-même Envoyer / Annuler / Accepter / Refuser.
class ConnectActionButton extends StatefulWidget {
  final int userId;
  final String userName;
  final ConnectionStatus initialStatus;
  final int? initialRequestId;
  // Après accepter/refuser une demande reçue — le profil n'a plus sa place
  // telle quelle dans une liste de découverte (devenu contact, ou plus
  // pertinent). Volontairement absent pour l'annulation d'une demande
  // envoyée : dans ce cas le profil doit rester visible avec "Se
  // connecter" à nouveau disponible.
  final VoidCallback? onResolved;

  const ConnectActionButton({
    super.key,
    required this.userId,
    required this.userName,
    this.initialStatus = ConnectionStatus.none,
    this.initialRequestId,
    this.onResolved,
  });

  @override
  State<ConnectActionButton> createState() => _ConnectActionButtonState();
}

class _ConnectActionButtonState extends State<ConnectActionButton> {
  final _service = ExploreService();
  late ConnectionStatus _status;
  int? _requestId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _requestId = widget.initialRequestId;
  }

  void _setStatus(ConnectionStatus status, {int? requestId}) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _requestId = requestId;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final id = await _service.connect(widget.userId);
      _setStatus(ConnectionStatus.pendingSent, requestId: id);
      _snack('Demande envoyée à ${widget.userName}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final requestId = _requestId;
    if (requestId == null) return;
    setState(() => _busy = true);
    try {
      await _service.cancel(requestId);
      _setStatus(ConnectionStatus.none);
      _snack('Demande à ${widget.userName} annulée');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(String action) async {
    final requestId = _requestId;
    if (requestId == null) return;
    setState(() => _busy = true);
    try {
      await _service.respond(requestId, action);
      _setStatus(ConnectionStatus.none);
      if (action == 'accept') {
        _snack('${widget.userName} ajouté à vos contacts');
      }
      widget.onResolved?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case ConnectionStatus.pendingSent:
        return SizedBox(
          height: 34,
          child: OutlinedButton.icon(
            onPressed: (_busy || _requestId == null)
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _cancel();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                  )
                : const Icon(Icons.close_rounded, size: 14),
            label: const Text('Envoyée', style: TextStyle(fontSize: 12.5)),
          ),
        );

      case ConnectionStatus.pendingReceived:
        if (_requestId == null) {
          return _Badge(label: 'Vous a invité·e', color: Colors.amber.shade700);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleActionButton(
              icon: Icons.close_rounded,
              color: Colors.red,
              busy: _busy,
              onTap: () {
                HapticFeedback.lightImpact();
                _respond('decline');
              },
            ),
            const SizedBox(width: 8),
            _CircleActionButton(
              icon: Icons.check_rounded,
              color: Colors.green,
              busy: _busy,
              onTap: () {
                HapticFeedback.lightImpact();
                _respond('accept');
              },
            ),
          ],
        );

      case ConnectionStatus.none:
        return SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: _busy
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _send();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _themeBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              disabledBackgroundColor: _themeBlue.withValues(alpha: 0.5),
            ),
            child: _busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Se connecter',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
          ),
        );
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: busy ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(icon, color: color, size: 18),
      ),
    );
  }
}

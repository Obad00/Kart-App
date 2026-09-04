import 'package:dio/dio.dart';
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

  /// true : bouton "Se connecter" compact (simple tap), pour une rangée
  /// étroite (ex: liste compacte d'Explorer) où le slider glissant n'a pas
  /// la place de fonctionner correctement (FractionallySizedBox(0.68) sur
  /// une largeur trop faible écrase aussi bien le texte que la piste).
  /// false (défaut) : geste "glisser pour se connecter", conçu pour une
  /// carte pleine largeur (cf. PublicCardPage). Les autres états (Envoyée/
  /// Accepter-Refuser) restent identiques dans les deux cas — déjà assez
  /// compacts pour tenir dans une rangée étroite.
  final bool compact;

  const ConnectActionButton({
    super.key,
    required this.userId,
    required this.userName,
    this.initialStatus = ConnectionStatus.none,
    this.initialRequestId,
    this.onResolved,
    this.compact = false,
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

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : null,
    ));
  }

  /// Message d'erreur lisible depuis une DioException — sans ça, un échec
  /// réseau/serveur sur Envoyer/Annuler/Accepter/Refuser ne montrait
  /// strictement rien à l'utilisateur : le bouton redevenait juste
  /// cliquable, sans aucune explication ("j'accepte et rien ne se passe").
  String _errorMessage(Object e) {
    if (e is DioException) {
      final serverMessage = e.response?.data is Map
          ? (e.response?.data as Map)['message']?.toString()
          : null;
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return serverMessage;
      }
    }
    return 'Une erreur est survenue, réessayez.';
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final id = await _service.connect(widget.userId);
      _setStatus(ConnectionStatus.pendingSent, requestId: id);
      _snack('Demande envoyée à ${widget.userName}');
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
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
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
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
    } catch (e) {
      _snack(_errorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case ConnectionStatus.contact:
        // Déjà un contact (ex: membre d'un réseau déjà connu) — rien à
        // proposer ici, juste un état visuel ; consulter/gérer le contact
        // se fait depuis l'onglet Contacts, pas depuis ce bouton.
        return const _Badge(label: 'Contact', color: Colors.green);

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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.grey),
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
        if (widget.compact) {
          return SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _send();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Se connecter',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
            ),
          );
        }
        // key: ValueKey(_busy) — si l'envoi échoue, _busy repasse à false
        // alors que le statut reste `none` : le widget est alors reconstruit
        // à neuf, ce qui remet naturellement le curseur à zéro sans code de
        // reset dédié.
        return _SlideToConnectButton(
          key: ValueKey(_busy),
          busy: _busy,
          onConfirm: () {
            HapticFeedback.mediumImpact();
            _send();
          },
        );
    }
  }
}

/// Piste "glisser pour se connecter" façon iOS, à la place d'un simple
/// bouton — sert uniquement pour l'action principale (aucune demande en
/// cours) ; les autres états (envoyée/reçue) restent des contrôles compacts
/// classiques, un geste de glissement n'y apportant rien.
class _SlideToConnectButton extends StatefulWidget {
  final bool busy;
  final VoidCallback onConfirm;

  const _SlideToConnectButton(
      {super.key, required this.busy, required this.onConfirm});

  @override
  State<_SlideToConnectButton> createState() => _SlideToConnectButtonState();
}

class _SlideToConnectButtonState extends State<_SlideToConnectButton>
    with SingleTickerProviderStateMixin {
  static const double _height = 46;
  static const double _thumbSize = 38;
  static const double _padding = 4;

  late final AnimationController _snapController;
  double _dragX = 0;
  double _maxDrag = 0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _dragX = _snapController.value);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_confirmed || widget.busy) return;
    setState(() {
      _dragX = (_dragX + details.delta.dx).clamp(0.0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_confirmed || widget.busy) return;
    final threshold = _maxDrag * 0.7;
    if (_dragX >= threshold) {
      setState(() {
        _confirmed = true;
        _dragX = _maxDrag;
      });
      widget.onConfirm();
    } else {
      _snapController.value = _dragX;
      _snapController.animateBack(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _confirmed || widget.busy;

    // Piste volontairement plus étroite que la carte (pas toute la largeur)
    // — un slider aussi large que le bouton "Voir la carte" d'avant donnait
    // l'impression d'un gros bouton plein plutôt que d'un geste ponctuel.
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.68,
        child: SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _maxDrag = (constraints.maxWidth - _thumbSize - _padding * 2)
                  .clamp(0.0, double.infinity);
              final progress =
                  _maxDrag == 0 ? 0.0 : (_dragX / _maxDrag).clamp(0.0, 1.0);

              return Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                      _themeBlue.withValues(alpha: 0.12), _themeBlue, progress),
                  borderRadius: BorderRadius.circular(_height / 2),
                  border: Border.all(color: _themeBlue.withValues(alpha: 0.3)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: (1 - progress * 1.4).clamp(0.0, 1.0),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: _thumbSize + _padding * 2),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          // "Se connecter" plutôt que "Glisser pour
                          // connecter" : plus court et plus lisible dans la
                          // piste à 68% de largeur, ce qui permet aussi une
                          // taille de texte plus grande sans être réduite
                          // par le FittedBox.
                          child: Text(
                            'Se connecter',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _themeBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: locked
                          ? const Duration(milliseconds: 200)
                          : Duration.zero,
                      curve: Curves.easeOut,
                      left: _padding + (locked ? _maxDrag : _dragX),
                      top: _padding,
                      child: GestureDetector(
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        child: Container(
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: const BoxDecoration(
                              color: _themeBlue, shape: BoxShape.circle),
                          child: widget.busy
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Icon(
                                  _confirmed
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
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
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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

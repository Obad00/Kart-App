import 'dart:async';

import 'package:flutter/widgets.dart';

/// Actualisation silencieuse des listes vivantes (participants, invitations
/// le jour J) : toutes les 20 s tant que l'écran est visible et l'app au
/// premier plan, et dès le retour dans l'app. [silentRefresh] remplace les
/// données sur place : ni loader, ni message d'erreur, ni saut de liste.
mixin SilentRefreshMixin<T extends StatefulWidget> on State<T> {
  static const interval = Duration(seconds: 20);

  Timer? _silentTimer;
  _ResumeObserver? _observer;
  bool _silentBusy = false;

  /// Recharge sans indicateur ; une erreur est ignorée (prochain essai).
  Future<void> silentRefresh();

  /// Écran réellement à l'écran : route au premier plan, onglet actif.
  /// À surcharger quand l'écran vit dans un IndexedStack.
  bool get silentRefreshVisible => ModalRoute.of(context)?.isCurrent ?? true;

  /// À appeler dans initState.
  void startSilentRefresh() {
    _observer = _ResumeObserver(silentRefreshTick);
    WidgetsBinding.instance.addObserver(_observer!);
    _silentTimer = Timer.periodic(interval, (_) => silentRefreshTick());
  }

  @visibleForTesting
  Future<void> silentRefreshTick() async {
    if (!mounted || _silentBusy || !silentRefreshVisible) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    _silentBusy = true;
    try {
      await silentRefresh();
    } catch (_) {
      // Silencieux par définition : le prochain passage réessaiera.
    } finally {
      _silentBusy = false;
    }
  }

  @override
  void dispose() {
    _silentTimer?.cancel();
    if (_observer != null) WidgetsBinding.instance.removeObserver(_observer!);
    super.dispose();
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;

  _ResumeObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

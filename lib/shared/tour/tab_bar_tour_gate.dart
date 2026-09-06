import 'dart:async';

/// Signale aux tours secondaires (Profil, Explorer, Contacts...) que
/// HomeShell a fini de décider s'il lance son propre tour de la barre de
/// navigation — et, le cas échéant, que ce tour est terminé.
///
/// Sans ce verrou, un tour secondaire démarrait dès le montage de son
/// onglet dans l'IndexedStack (donc dès le tout premier frame, comme les 5
/// onglets), souvent avant même que celui de la barre de nav (qui attend
/// plusieurs appels réseau/async avant de démarrer) ait eu le temps de
/// s'afficher — ce qui donnait l'impression que le guide commençait par la
/// mauvaise partie de l'app (ex: la photo de profil au lieu de la barre de
/// nav).
class TabBarTourGate {
  TabBarTourGate._();

  static final Completer<void> _completer = Completer<void>();

  /// Se résout dès que la séquence de la barre de nav est terminée (ou
  /// qu'il n'y en avait pas à montrer).
  static Future<void> get ready => _completer.future;

  static void open() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

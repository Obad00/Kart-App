/// Contrôle d'accès JobMatch — volontairement strict sur le plan 'pro'.
/// Ne pas réutiliser `User.isPro` ici : il vaut aussi `true` pour 'enterprise'.
bool canAccessJobMatch(String? plan) {
  return (plan ?? '').trim().toLowerCase() == 'pro';
}

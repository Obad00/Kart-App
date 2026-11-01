/// Accord en nombre à la française : 0 et 1 au singulier (« 1 highlight »,
/// « 0 contact »), au-delà le pluriel (« 2 highlights »).
String plural(int count, String singular, [String? pluralForm]) =>
    '$count ${count.abs() < 2 ? singular : (pluralForm ?? '${singular}s')}';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../data/public_card_settings_service.dart';
import 'package:flutter/painting.dart' show Color;

import '../models/public_card_settings.dart';
import '../public_card_styles.dart';

/// État de l'écran « Personnaliser ma carte publique » : les réglages
/// enregistrés, et le brouillon en cours de modification (rien n'est envoyé
/// avant « Enregistrer »).
class PublicCardSettingsProvider extends ChangeNotifier {
  PublicCardSettingsProvider({
    PublicCardSettingsService service = const PublicCardSettingsService(),
    List<String> fallbackActivatedFields = const [],
  })  : _service = service,
        _fallbackActivatedFields = fallbackActivatedFields;

  final PublicCardSettingsService _service;

  /// `activated_fields` de la carte déjà chargée par l'app, utilisés si
  /// l'API ne les renvoie pas avec les réglages.
  final List<String> _fallbackActivatedFields;
  bool _disposed = false;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  PublicCardSettingsData? _saved;
  Set<String> _savedFields = const {};

  PublicCardSettings _draft = const PublicCardSettings();
  Set<String> _draftFields = const {};

  /// Couleur choisie dans cet écran et pas encore enregistrée ; null =
  /// celle du serveur.
  Color? _draftAccent;

  bool get loading => _loading;
  bool get saving => _saving;

  /// Message d'erreur du chargement, null s'il a réussi.
  String? get error => _error;
  bool get isReady => _saved != null;

  String get slug => _saved?.slug ?? '';
  PublicCardSettings get settings => _draft;

  /// Couleur d'accent de l'aperçu : celle choisie ici si elle n'est pas
  /// encore enregistrée, sinon celle du serveur pour le thème affiché.
  EffectiveAccent get accent {
    final server =
        (_saved?.accent ?? EffectiveAccent.fallback).forTheme(_draft.theme);
    final draft = _draftAccent;
    if (draft == null || accentLocked) return server;
    return EffectiveAccent(
      color: draft,
      onColor: PublicCardStyles.onColor(draft),
    );
  }

  /// true = couleur imposée par l'entreprise : elle ne se change pas ici.
  bool get accentLocked => _saved?.accent.fromCompany ?? false;

  bool get hasChanges =>
      _saved != null &&
      (_draft != _saved!.settings ||
          !setEquals(_draftFields, _savedFields) ||
          _draftAccent != null);

  /// Choisit une couleur d'accent (pastille ou sélecteur). Sans effet si
  /// l'entreprise impose la sienne.
  void setAccent(Color color) {
    if (accentLocked) return;
    final current = (_saved?.accent ?? EffectiveAccent.fallback).color;
    _draftAccent = color.toARGB32() == current.toARGB32() ? null : color;
    _notify();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();

    try {
      _apply(await _service.fetch());
    } catch (e) {
      _error = getErrorMessage(
        e,
        fallback: 'Impossible de charger vos réglages. Réessayez.',
      );
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _apply(PublicCardSettingsData data, {Set<String>? fields}) {
    _saved = data;
    _savedFields =
        fields ?? (data.activatedFields ?? _fallbackActivatedFields).toSet();
    _draft = data.settings;
    _draftFields = {..._savedFields};
    _draftAccent = null;
  }

  /// Recharge seulement la couleur d'accent (après un passage par
  /// « Couleur et logo »), sans toucher au brouillon en cours.
  Future<void> refreshAccent() async {
    final saved = _saved;
    if (saved == null) return;
    try {
      final fresh = await _service.fetch();
      _saved = PublicCardSettingsData(
        slug: saved.slug,
        settings: saved.settings,
        accent: fresh.accent,
        activatedFields: saved.activatedFields,
      );
      _notify();
    } catch (_) {
      // Sans réseau, l'aperçu garde simplement l'ancienne couleur.
    }
  }

  void setLayout(String layout) => _edit(_draft.copyWith(layout: layout));
  void setTheme(String theme) => _edit(_draft.copyWith(theme: theme));
  void setCardStyle(String style) => _edit(_draft.copyWith(cardStyle: style));

  void _edit(PublicCardSettings settings) {
    _draft = settings;
    _notify();
  }

  /// Déplace une section (indices de ReorderableListView).
  void reorder(int oldIndex, int newIndex) {
    final order = [..._draft.order];
    if (newIndex > oldIndex) newIndex -= 1;
    order.insert(newIndex, order.removeAt(oldIndex));
    _edit(_draft.copyWith(order: order));
  }

  /// Une section de contact est visible dès qu'un de ses champs l'est.
  bool isVisible(String section) {
    final fields = PublicCardSettings.fieldsOf[section];
    if (fields != null) return fields.any(_draftFields.contains);
    return !_draft.hiddenSections.contains(section);
  }

  void setVisible(String section, bool visible) {
    final fields = PublicCardSettings.fieldsOf[section];
    if (fields != null) {
      _draftFields = visible
          ? {..._draftFields, ...fields}
          : _draftFields.difference(fields.toSet());
      _notify();
      return;
    }
    final hidden = _draft.hiddenSections.where((s) => s != section).toList();
    if (!visible) hidden.add(section);
    _edit(_draft.copyWith(hiddenSections: hidden));
  }

  /// Remet la présentation par défaut dans le brouillon (disposition,
  /// thème, style, ordre, sections masquées). La visibilité du téléphone,
  /// de l'email, des réseaux et du site n'est pas touchée.
  void resetToDefaults() => _edit(const PublicCardSettings());

  /// Renvoie un message d'erreur à afficher, ou null si tout est
  /// enregistré.
  Future<String?> save() async {
    final saved = _saved;
    if (saved == null) return 'Réglages non chargés.';

    _saving = true;
    _notify();
    try {
      // La carte d'abord (visibilité des contacts, couleur) : si l'appel
      // échoue, rien n'a encore changé.
      final fields = _draftFields;
      final fieldsChanged = !setEquals(fields, _savedFields);
      final accent = _draftAccent;
      if (fieldsChanged || accent != null) {
        await _service.saveCard(
          activatedFields: fieldsChanged ? (fields.toList()..sort()) : null,
          accentHex: accent == null ? null : PublicCardStyles.toHex(accent),
        );
        _savedFields = {...fields};
      }
      // Puis la présentation. Relue aussi après un changement de couleur :
      // le serveur renvoie la couleur effective (et sa variante claire).
      final draft = _draft;
      _apply(
        draft != saved.settings
            ? await _service.save(draft)
            : (accent != null ? await _service.fetch() : saved),
        fields: fields,
      );
      return null;
    } catch (e) {
      return getErrorMessage(
        e,
        fallback: "Vos réglages n'ont pas pu être enregistrés. Réessayez.",
      );
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

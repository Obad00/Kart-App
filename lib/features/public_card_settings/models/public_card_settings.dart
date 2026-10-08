import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Réglages de la page publique `kart.business/card/{slug}` — mêmes clés et
/// mêmes valeurs que `App\Support\PublicCardSettings` côté API, qui reste la
/// référence (les listes ci-dessous ne servent que de repli).
@immutable
class PublicCardSettings {
  const PublicCardSettings({
    this.layout = 'physical',
    this.theme = 'dark',
    this.cardStyle = 'mat',
    this.order = defaultOrder,
    this.hiddenSections = const [],
  });

  /// Dispositions proposées : celles que le site en ligne sait afficher.
  /// L'API en accepte d'autres (bento, editorial) ; elles seront ajoutées
  /// ici quand le site les aura.
  static const layouts = ['physical', 'classic', 'banner'];
  static const themes = ['dark', 'light'];
  static const cardStyles = ['mat', 'gradient', 'marine'];

  static const defaultOrder = [
    'bio', 'phone', 'whatsapp', 'email', 'website', 'socials', //
    'company', 'skills', 'experiences', 'educations', 'interests',
  ];

  /// Sections dont la visibilité est dans `activated_fields` (comme dans le
  /// formulaire « Modifier mes infos »), pas dans [hiddenSections].
  static const contactSections = ['phone', 'email', 'website', 'socials'];

  /// Champs de `activated_fields` pilotés par chaque section de contact.
  static const fieldsOf = {
    'phone': ['phone'],
    'email': ['email'],
    'website': ['website'],
    'socials': ['linkedin', 'instagram', 'facebook', 'github'],
  };

  final String layout;
  final String theme;
  final String cardStyle;
  final List<String> order;
  final List<String> hiddenSections;

  factory PublicCardSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PublicCardSettings();
    String pick(String key, List<String> allowed, String fallback) {
      final value = json[key];
      return value is String && allowed.contains(value) ? value : fallback;
    }

    List<String> strings(String key) =>
        (json[key] as List?)?.whereType<String>().toList() ?? const [];

    // Ordre reçu, sans doublon ni clé inconnue, complété par les sections
    // manquantes à leur place par défaut.
    final order = <String>[];
    for (final key in [...strings('order'), ...defaultOrder]) {
      if (defaultOrder.contains(key) && !order.contains(key)) order.add(key);
    }

    return PublicCardSettings(
      layout: pick('layout', layouts, 'physical'),
      theme: pick('theme', themes, 'dark'),
      cardStyle: pick('card_style', cardStyles, 'mat'),
      order: order,
      hiddenSections: strings('hidden_sections')
          .where((s) => !contactSections.contains(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'layout': layout,
        'theme': theme,
        'card_style': cardStyle,
        'order': order,
        'hidden_sections': hiddenSections,
      };

  PublicCardSettings copyWith({
    String? layout,
    String? theme,
    String? cardStyle,
    List<String>? order,
    List<String>? hiddenSections,
  }) =>
      PublicCardSettings(
        layout: layout ?? this.layout,
        theme: theme ?? this.theme,
        cardStyle: cardStyle ?? this.cardStyle,
        order: order ?? this.order,
        hiddenSections: hiddenSections ?? this.hiddenSections,
      );

  @override
  bool operator ==(Object other) =>
      other is PublicCardSettings &&
      other.layout == layout &&
      other.theme == theme &&
      other.cardStyle == cardStyle &&
      listEquals(other.order, order) &&
      setEquals(other.hiddenSections.toSet(), hiddenSections.toSet());

  @override
  int get hashCode => Object.hash(layout, theme, cardStyle,
      Object.hashAll(order), Object.hashAllUnordered(hiddenSections));
}

/// Couleur d'accent de la page publique, choisie par l'API
/// (`effective_accent`) : entreprise, sinon carte, sinon défaut. L'app ne
/// refait jamais ce choix.
@immutable
class EffectiveAccent {
  const EffectiveAccent({
    required this.color,
    required this.onColor,
    this.fromCompany = false,
    this.byTheme = const {},
  });

  /// Or KART : celui de la page publique quand aucune couleur n'est choisie.
  static const fallback = EffectiveAccent(
    color: Color(0xFFC99A2E),
    onColor: Color(0xFF000000),
  );

  final Color color;

  /// Noir ou blanc : le texte lisible posé sur [color].
  final Color onColor;

  /// true = couleur imposée par l'entreprise (affichée verrouillée).
  final bool fromCompany;

  final Map<String, EffectiveAccent> byTheme;

  /// Couleur pour un thème donné (aperçu d'un thème pas encore enregistré).
  EffectiveAccent forTheme(String theme) => byTheme[theme] ?? this;

  /// null si la réponse ne contient pas d'`effective_accent` exploitable
  /// (ancienne API) : l'appelant garde alors son repli.
  static EffectiveAccent? tryParse(Object? json) {
    if (json is! Map) return null;
    final color = parseHex(json['color']);
    if (color == null) return null;
    final fromCompany = json['source'] == 'company';

    final byTheme = <String, EffectiveAccent>{};
    final themes = json['by_theme'];
    if (themes is Map) {
      themes.forEach((key, value) {
        final themed = value is Map ? parseHex(value['color']) : null;
        if (key is String && themed != null) {
          byTheme[key] = EffectiveAccent(
            color: themed,
            onColor: parseHex((value as Map)['on_color']) ?? _onColor(themed),
            fromCompany: fromCompany,
          );
        }
      });
    }

    return EffectiveAccent(
      color: color,
      onColor: parseHex(json['on_color']) ?? _onColor(color),
      fromCompany: fromCompany,
      byTheme: byTheme,
    );
  }

  static Color _onColor(Color color) =>
      color.computeLuminance() > 0.179 ? Colors.black : Colors.white;

  static Color? parseHex(Object? value) {
    if (value is! String) return null;
    var hex = value.trim().replaceFirst('#', '');
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    if (hex.length != 6) return null;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(0xFF000000 | parsed);
  }
}

/// Ce que renvoie GET /me/card/public-settings.
@immutable
class PublicCardSettingsData {
  const PublicCardSettingsData({
    required this.slug,
    required this.settings,
    required this.accent,
    required this.activatedFields,
  });

  final String slug;
  final PublicCardSettings settings;
  final EffectiveAccent accent;

  /// Champs de contact visibles (`activated_fields`). null si l'API ne les
  /// renvoie pas encore ici : l'écran les lit alors dans la carte chargée.
  final List<String>? activatedFields;

  factory PublicCardSettingsData.fromJson(Map<String, dynamic> json) =>
      PublicCardSettingsData(
        slug: json['slug'] as String? ?? '',
        settings: PublicCardSettings.fromJson(
          (json['public_settings'] as Map?)?.cast<String, dynamic>(),
        ),
        accent: EffectiveAccent.tryParse(json['effective_accent']) ??
            EffectiveAccent.fallback,
        activatedFields:
            (json['activated_fields'] as List?)?.whereType<String>().toList(),
      );
}

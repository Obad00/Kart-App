import 'dart:ui' show Color;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart' show ImageProvider;

/// Contenu affiché sur la carte de visite (faces QR et infos) — assemblé
/// par MyDigitalCardPage à partir de CardProvider/AuthProvider, pour que les
/// widgets de la carte restent purement visuels.
class KartCardData {
  final String fullName;
  final String? jobTitle;

  /// Nom affiché à côté du logo (entreprise pour un compte entreprise).
  final String? brandName;

  /// Logo de l'entreprise, logo personnel, ou photo de profil en repli.
  final String? logoUrl;

  /// true quand [logoUrl] est la photo de profil (repli) : affichée en rond
  /// plutôt qu'en tuile carrée.
  final bool logoIsPhoto;

  /// Logo entier, à son ratio d'origine (horizontal, vertical...) : affiché
  /// sans jamais être coupé. null pour une photo de profil ou un logo
  /// envoyé avant ce traitement — la tuile carrée [logoUrl] sert alors.
  final String? logoFullUrl;

  /// false = logo opaque (souvent sur fond blanc) : posé dans une pastille
  /// claire sur la carte sombre. true = logo détouré, posé directement.
  final bool? logoTransparent;

  /// Image injectée à la place du téléchargement de [logoFullUrl] : les
  /// tests de rendu n'ont pas de réseau. L'app ne le renseigne jamais, et
  /// lit toujours [logoFullProvider].
  @visibleForTesting
  final ImageProvider? logoFullImage;

  /// Badge discret à côté de "KART" (ex: 'PRO' pour un compte entreprise).
  final String? badgeLabel;

  final String? phone;
  final String? email;
  final String? city;

  /// Couleur choisie (entreprise, sinon accent personnel) qui teinte le
  /// fond noir de la carte ; null = noir mat.
  final Color? tint;

  const KartCardData({
    required this.fullName,
    this.jobTitle,
    this.brandName,
    this.logoUrl,
    this.logoIsPhoto = false,
    this.logoFullUrl,
    this.logoTransparent,
    this.logoFullImage,
    this.badgeLabel,
    this.phone,
    this.email,
    this.city,
    this.tint,
  });

  static bool _filled(String? v) => v != null && v.trim().isNotEmpty;

  bool get hasJobTitle => _filled(jobTitle);
  bool get hasBrandName => _filled(brandName);
  bool get hasLogo => _filled(logoUrl);
  bool get hasFullLogo => !logoIsPhoto && _filled(logoFullUrl);

  /// Source de l'image du logo entier (à n'appeler que si [hasFullLogo]).
  ImageProvider get logoFullProvider =>
      logoFullImage ?? CachedNetworkImageProvider(logoFullUrl!);
  bool get hasPhone => _filled(phone);
  bool get hasEmail => _filled(email);
  bool get hasCity => _filled(city);
}

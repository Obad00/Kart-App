import 'dart:ui' show Color;

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
  bool get hasPhone => _filled(phone);
  bool get hasEmail => _filled(email);
  bool get hasCity => _filled(city);
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Au-delà, un logo OPAQUE est converti en JPG : un PNG de photo ou de
/// capture d'écran pèse vite plusieurs Mo pour rien.
const int logoJpegThresholdBytes = 1500 * 1024;

/// Limite du serveur (validation `max:5120`) : on ne l'atteint jamais.
const int logoMaxUploadBytes = 5 * 1024 * 1024;

/// Le logo dépasse 5 Mo même une fois allégé.
class LogoTooLargeException implements Exception {
  final String message;

  const LogoTooLargeException([
    this.message = 'Ce logo est trop lourd (5 Mo maximum).',
  ]);

  @override
  String toString() => message;
}

/// Prépare un logo avant l'envoi et renvoie le chemin du fichier à envoyer :
///  - 1,5 Mo ou moins : envoyé tel quel ;
///  - plus lourd et opaque (aucun pixel transparent) : converti en JPG
///    qualité 90 ;
///  - plus lourd et transparent : reste en PNG, pour garder le détourage.
/// Dans tous les cas le fichier envoyé fait 5 Mo au plus : sinon il est
/// réduit, et en dernier recours [LogoTooLargeException] est levée.
///
/// Le travail d'image se fait dans un isolate : décoder et réencoder une
/// image de plusieurs Mo figerait l'écran.
Future<String> prepareLogoForUpload(String path) async {
  final size = await File(path).length();
  if (size <= logoJpegThresholdBytes) return path;

  final prepared = await compute(_prepare, path);
  if (prepared == null) {
    // Image illisible ici : le serveur tranchera, tant qu'elle passe.
    if (size > logoMaxUploadBytes) throw const LogoTooLargeException();
    return path;
  }

  if (prepared.bytes.length > logoMaxUploadBytes) {
    throw const LogoTooLargeException();
  }

  final dot = path.lastIndexOf('.');
  final base = dot > path.lastIndexOf('/') ? path.substring(0, dot) : path;
  final output = '${base}_upload.${prepared.extension}';
  await File(output).writeAsBytes(prepared.bytes, flush: true);
  return output;
}

class _Prepared {
  final Uint8List bytes;
  final String extension;

  const _Prepared(this.bytes, this.extension);
}

_Prepared? _prepare(String path) {
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) return null;

  // Photo de téléphone : on applique son orientation EXIF, que le JPG
  // réencodé ne porterait plus.
  var image = img.bakeOrientation(decoded);
  final transparent = _hasTransparency(image);

  Uint8List encode(img.Image source) => transparent
      ? img.encodePng(source)
      : img.encodeJpg(source, quality: 90);

  var bytes = encode(image);

  // Encore trop lourd (rare : grand PNG transparent) : on réduit par paliers.
  for (final maxSide in const [1600, 1024, 768]) {
    if (bytes.length <= logoMaxUploadBytes) break;
    if (image.width <= maxSide && image.height <= maxSide) continue;
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
    bytes = encode(image);
  }

  return _Prepared(bytes, transparent ? 'png' : 'jpg');
}

/// Vrai si au moins un pixel n'est pas totalement opaque. Un PNG a souvent
/// un canal alpha sans s'en servir : seul le contenu fait foi.
bool _hasTransparency(img.Image image) {
  if (!image.hasAlpha) return false;
  final opaque = image.maxChannelValue;
  for (final pixel in image) {
    if (pixel.a < opaque) return true;
  }
  return false;
}

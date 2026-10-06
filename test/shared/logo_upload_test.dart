// Poids du logo avant l'envoi : un logo opaque lourd part en JPG, un logo
// transparent reste en PNG, et rien ne dépasse 5 Mo (limite du serveur).
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kart_app/shared/utils/logo_upload.dart';

late Directory _dir;

/// Image "bruitée" (incompressible), pour obtenir un PNG lourd.
String _noisyPng(String name, int side, {bool transparentCorner = false}) {
  final random = Random(42);
  final image = img.Image(width: side, height: side, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256)
      ..a = 255;
  }
  if (transparentCorner) {
    for (var y = 0; y < side ~/ 4; y++) {
      for (var x = 0; x < side ~/ 4; x++) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  final path = '${_dir.path}/$name';
  File(path).writeAsBytesSync(img.encodePng(image));
  return path;
}

void main() {
  setUp(() => _dir = Directory.systemTemp.createTempSync('logo_upload'));
  tearDown(() => _dir.deleteSync(recursive: true));

  test('un petit logo est envoyé tel quel', () async {
    final image = img.Image(width: 400, height: 100)
      ..clear(img.ColorRgb8(11, 43, 91));
    final path = '${_dir.path}/petit.png';
    File(path).writeAsBytesSync(img.encodePng(image));

    expect(await prepareLogoForUpload(path), path);
  });

  test('un logo opaque de plus de 1,5 Mo est converti en JPG', () async {
    final path = _noisyPng('lourd.png', 900);
    expect(File(path).lengthSync(), greaterThan(logoJpegThresholdBytes));

    final output = await prepareLogoForUpload(path);

    expect(output, endsWith('.jpg'));
    expect(File(output).lengthSync(), lessThan(File(path).lengthSync()));
    expect(File(output).lengthSync(), lessThanOrEqualTo(logoMaxUploadBytes));

    // Toujours une image lisible, aux mêmes dimensions.
    final decoded = img.decodeJpg(File(output).readAsBytesSync())!;
    expect(decoded.width, 900);
    expect(decoded.height, 900);
  });

  test('un logo transparent lourd reste en PNG', () async {
    final path = _noisyPng('detoure.png', 900, transparentCorner: true);
    expect(File(path).lengthSync(), greaterThan(logoJpegThresholdBytes));

    final output = await prepareLogoForUpload(path);

    expect(output, endsWith('.png'));
    final decoded = img.decodePng(File(output).readAsBytesSync())!;
    expect(decoded.getPixel(0, 0).a, 0); // le détourage est conservé
    expect(File(output).lengthSync(), lessThanOrEqualTo(logoMaxUploadBytes));
  });

  test('un PNG transparent de plus de 5 Mo est réduit sous la limite',
      () async {
    final path = _noisyPng('enorme.png', 1500, transparentCorner: true);
    expect(File(path).lengthSync(), greaterThan(logoMaxUploadBytes));

    final output = await prepareLogoForUpload(path);

    expect(output, endsWith('.png'));
    expect(File(output).lengthSync(), lessThanOrEqualTo(logoMaxUploadBytes));
  });

  test('un fichier illisible de plus de 5 Mo est refusé avant l\'envoi',
      () async {
    final path = '${_dir.path}/faux.png';
    File(path).writeAsBytesSync(List.filled(logoMaxUploadBytes + 1, 7));

    expect(
      () => prepareLogoForUpload(path),
      throwsA(isA<LogoTooLargeException>()),
    );
  });
}

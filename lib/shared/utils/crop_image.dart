import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Ouvre l'écran de recadrage natif juste après un ImagePicker.pickImage —
/// sans ça, l'image partait telle quelle vers un cercle (avatar) ou un
/// carré (logo entreprise), recadrée automatiquement par le centre sans
/// que l'utilisateur puisse choisir la zone (front/menton coupés...).
/// Toujours en carré 1:1 (verrouillé) : c'est le seul format utilisé pour
/// un avatar ou un logo dans l'app. Retourne le CroppedFile (utiliser
/// .readAsBytes(), pas dart:io File — non disponible/valide sur web), ou
/// `null` si l'utilisateur annule (aucune image à uploader dans ce cas).
Future<CroppedFile?> cropPickedImage(
  BuildContext context,
  String sourcePath, {
  CropStyle cropStyle = CropStyle.rectangle,
}) async {
  return ImageCropper().cropImage(
    sourcePath: sourcePath,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 90,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recadrer',
        cropStyle: cropStyle,
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: 'Recadrer',
        cropStyle: cropStyle,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
      // Web (tests locaux via `flutter run -d chrome`) — sans ce réglage,
      // le recadrage silencieusement ignoré sur cette plateforme
      // (uiSettings Android/iOS n'y ont aucun effet).
      WebUiSettings(context: context),
    ],
  );
}

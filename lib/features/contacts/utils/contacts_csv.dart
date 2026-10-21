import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact_model.dart';

/// Export des contacts en CSV (toutes les infos disponibles), partagé par
/// la liste des contacts et par l'écran « Compte suspendu ».
String contactsToCsv(List<ContactModel> contacts) {
  const headers = [
    'Nom',
    'Email',
    'Téléphone',
    'Entreprise',
    'Poste',
    'LinkedIn',
    'Twitter',
    'Facebook',
    'Instagram',
    'Site Web',
    'Highlight',
    'Date de rencontre',
    'Favori',
  ];

  final rows = contacts
      .map((contact) => [
            contact.fullname,
            contact.email ?? '',
            contact.phone ?? '',
            contact.company ?? '',
            contact.job ?? '',
            contact.linkedin ?? '',
            contact.twitter ?? '',
            contact.facebook ?? '',
            contact.instagram ?? '',
            contact.website ?? '',
            contact.highlightName ?? '',
            contact.capturedAt != null
                ? '${contact.capturedAt!.day.toString().padLeft(2, '0')}/'
                    '${contact.capturedAt!.month.toString().padLeft(2, '0')}/'
                    '${contact.capturedAt!.year}'
                : '',
            contact.isFavorite ? 'Oui' : 'Non',
          ])
      .toList();

  return const ListToCsvConverter().convert([headers, ...rows]);
}

/// Écrit le CSV dans les documents de l'app et ouvre la feuille de partage.
Future<void> shareContactsCsv(List<ContactModel> contacts) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/contacts_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(contactsToCsv(contacts));

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Mes contacts KART',
    ),
  );
}

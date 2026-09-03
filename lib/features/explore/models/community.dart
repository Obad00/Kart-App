import 'package:flutter/material.dart';

/// "Réseaux populaires" — communautés créées par le superadmin (CRM web),
/// affichées en scroll horizontal sur l'onglet "Découvrir" de la page
/// Explorer. Voir CommunityController côté backend.
class Community {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final Color color;
  final int membersCount;
  // Avatars des membres les plus récents — jusqu'à 5, pour la pile de
  // cercles qui se chevauchent sur la carte (cf. maquette).
  final List<String> previewAvatars;
  final bool isJoined;

  Community({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.color,
    required this.membersCount,
    this.previewAvatars = const [],
    this.isJoined = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      color: _colorFromHex(json['color']),
      membersCount: int.tryParse(json['membersCount']?.toString() ?? '') ?? 0,
      previewAvatars: (json['previewAvatars'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isJoined: json['isJoined'] == true,
    );
  }

  static Color _colorFromHex(dynamic value) {
    final hex = (value ?? '').toString().replaceAll('#', '');
    if (hex.length != 6) return const Color(0xFF7C3AED);
    final intValue = int.tryParse('FF$hex', radix: 16);
    return intValue != null ? Color(intValue) : const Color(0xFF7C3AED);
  }

  Community copyWith({bool? isJoined, int? membersCount}) {
    return Community(
      id: id,
      name: name,
      slug: slug,
      description: description,
      color: color,
      membersCount: membersCount ?? this.membersCount,
      previewAvatars: previewAvatars,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

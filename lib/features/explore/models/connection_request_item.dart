import 'explore_user.dart';

enum RequestDirection { sent, received }

class ConnectionRequestItem {
  final int id;
  final RequestDirection direction;
  final String status; // pending | accepted | declined
  final DateTime? createdAt;
  final ExploreUser otherUser;

  ConnectionRequestItem({
    required this.id,
    required this.direction,
    required this.status,
    required this.otherUser,
    this.createdAt,
  });

  factory ConnectionRequestItem.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      direction:
          json['direction'] == 'sent' ? RequestDirection.sent : RequestDirection.received,
      status: json['status'] ?? 'pending',
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      otherUser: ExploreUser.fromJson(json['otherUser'] as Map<String, dynamic>),
    );
  }
}

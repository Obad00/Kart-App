class HighlightModel {
  final int id;
  final String name;
  final bool isActive;

  HighlightModel({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      id: json['id'],
      name: json['name'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

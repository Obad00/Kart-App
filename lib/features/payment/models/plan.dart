class Plan {
  final int id;
  final String name;
  final String slug;
  final String description;
  final int price;
  final String billingCycle;
  final List<String> features;
  final bool isActive;

  Plan({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.isActive,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] is String 
          ? (double.tryParse(json['price'] as String)?.round() ?? 0) 
          : ((json['price'] as num?)?.round() ?? 0),
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : [],
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get isFree => price == 0;

  String get formattedPrice {
    if (isFree) return 'Gratuit';
    return '${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} FCFA';
  }

  String get billingCycleLabel {
    switch (billingCycle) {
      case 'monthly':
        return '/mois';
      case 'yearly':
        return '/an';
      default:
        return '';
    }
  }
}

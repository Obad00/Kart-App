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
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] ?? '',
      price: json['price'] ?? 0,
      billingCycle: json['billing_cycle'] ?? 'monthly',
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : [],
      isActive: json['is_active'] ?? true,
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

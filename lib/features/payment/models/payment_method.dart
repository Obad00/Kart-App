import 'package:flutter/material.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String icon;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'payment',
    );
  }

  IconData get iconData {
    switch (icon) {
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'credit-card':
      case 'card':
        return Icons.credit_card_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }
}

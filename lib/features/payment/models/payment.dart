enum PaymentStatus {
  pending,
  successful,
  failed,
}

class Payment {
  final String reference;
  final PaymentStatus status;
  final int amount;
  final String currency;
  final String paymentMethod;
  final PaymentPlan? plan;
  final DateTime? paidAt;

  Payment({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.plan,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      reference: json['reference'],
      status: _parseStatus(json['status']),
      amount: json['amount'] is String
          ? (double.tryParse(json['amount'] as String)?.round() ?? 0)
          : ((json['amount'] as num?)?.round() ?? 0),
      currency: json['currency'] ?? 'XOF',
      paymentMethod: json['payment_method'] ?? '',
      plan: json['plan'] != null ? PaymentPlan.fromJson(json['plan']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
    );
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status) {
      case 'successful':
        return PaymentStatus.successful;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }

  bool get isPending => status == PaymentStatus.pending;
  bool get isSuccessful => status == PaymentStatus.successful;
  bool get isFailed => status == PaymentStatus.failed;

  String get formattedAmount {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} $currency';
  }
}

class PaymentPlan {
  final int id;
  final String name;
  final String slug;

  PaymentPlan({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}

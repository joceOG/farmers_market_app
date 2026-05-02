import 'transaction_item.dart';

enum PaymentMethod { cash, credit }

enum TransactionStatus { open, closed }

extension PaymentMethodX on PaymentMethod {
  String get value => name; // 'cash' | 'credit'
  String get label => this == PaymentMethod.cash ? 'Espèces' : 'Crédit';

  static PaymentMethod fromString(String s) =>
      s == 'credit' ? PaymentMethod.credit : PaymentMethod.cash;
}

class Transaction {
  final int id;
  final int farmerId;
  final int operatorId;
  final double totalFcfa;
  final PaymentMethod paymentMethod;
  final double? interestRate;
  final double? creditedAmount;
  final List<TransactionItem> items;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.farmerId,
    required this.operatorId,
    required this.totalFcfa,
    required this.paymentMethod,
    this.interestRate,
    this.creditedAmount,
    this.items = const [],
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      farmerId: json['farmer_id'] as int,
      operatorId: json['operator_id'] as int,
      totalFcfa: (json['total_fcfa'] as num).toDouble(),
      paymentMethod: PaymentMethodX.fromString(
          json['payment_method'] as String? ?? 'cash'),
      interestRate: json['interest_rate'] != null
          ? (json['interest_rate'] as num).toDouble()
          : null,
      creditedAmount: json['credited_amount'] != null
          ? (json['credited_amount'] as num).toDouble()
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => TransactionItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'operator_id': operatorId,
    'total_fcfa': totalFcfa,
    'payment_method': paymentMethod.value,
    'interest_rate': interestRate,
    'credited_amount': creditedAmount,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isCredit => paymentMethod == PaymentMethod.credit;

  /// Montant final (avec intérêts si crédit)
  double get finalAmount => creditedAmount ?? totalFcfa;

  @override
  String toString() =>
      'Transaction(id: $id, total: $totalFcfa, method: ${paymentMethod.value})';
}

/// DTO pour créer une transaction (POST /transactions)
class TransactionRequest {
  final int farmerId;
  final PaymentMethod paymentMethod;
  final double? interestRate;
  final List<TransactionItemRequest> items;

  const TransactionRequest({
    required this.farmerId,
    required this.paymentMethod,
    this.interestRate,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'farmer_id': farmerId,
    'payment_method': paymentMethod.value,
    if (interestRate != null) 'interest_rate': interestRate,
    'items': items.map((i) => i.toJson()).toList(),
  };
}
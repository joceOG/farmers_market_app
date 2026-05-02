class Debt {
  final int id;
  final int transactionId;  // ✅ FK → transactions
  final int farmerId;       // ✅ FK → farmers
  final double amountFcfa;  // ✅ schéma : amount_fcfa
  final double amountPaid;  // ✅ schéma : amount_paid
  final String status;      // ✅ enum : "open" | "closed"

  const Debt({
    required this.id,
    required this.transactionId,
    required this.farmerId,
    required this.amountFcfa,
    required this.amountPaid,
    required this.status,
  });

  bool get isActive => status == 'open';
  bool get isClosed => status == 'closed';

  double get remainingAmount => amountFcfa - amountPaid;
  double get progressPercent =>
      amountFcfa == 0 ? 0 : (amountPaid / amountFcfa * 100).clamp(0, 100);

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as int,
      transactionId: json['transaction_id'] as int,
      farmerId: json['farmer_id'] as int,
      amountFcfa: (json['amount_fcfa'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'open',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'farmer_id': farmerId,
    'amount_fcfa': amountFcfa,
    'amount_paid': amountPaid,
    'status': status,
  };
}
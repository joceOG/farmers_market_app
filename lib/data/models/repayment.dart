import 'repayment_debt.dart';

class Repayment {
  final int id;
  final int farmerId;
  final int operatorId;
  final double kgReceived;
  final double rateFcfaPerKg;
  final double totalFcfaValue;
  final List<RepaymentDebt> repaymentDebts; // détail FIFO

  const Repayment({
    required this.id,
    required this.farmerId,
    required this.operatorId,
    required this.kgReceived,
    required this.rateFcfaPerKg,
    required this.totalFcfaValue,
    this.repaymentDebts = const [],
  });

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'] as int,
      farmerId: json['farmer_id'] as int,
      operatorId: json['operator_id'] as int,
      kgReceived: (json['kg_received'] as num).toDouble(),
      rateFcfaPerKg: (json['rate_fcfa_per_kg'] as num).toDouble(),
      totalFcfaValue: (json['total_fcfa_value'] as num).toDouble(),
      repaymentDebts: (json['repayment_debts'] as List<dynamic>? ?? [])
          .map((r) => RepaymentDebt.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'operator_id': operatorId,
    'kg_received': kgReceived,
    'rate_fcfa_per_kg': rateFcfaPerKg,
    'total_fcfa_value': totalFcfaValue,
  };
}
class RepaymentDebt {
  final int id;
  final int repaymentId;
  final int debtId;
  final double amountApplied; // montant imputé sur cette dette (FIFO)

  const RepaymentDebt({
    required this.id,
    required this.repaymentId,
    required this.debtId,
    required this.amountApplied,
  });

  factory RepaymentDebt.fromJson(Map<String, dynamic> json) {
    return RepaymentDebt(
      id: json['id'] as int,
      repaymentId: json['repayment_id'] as int,
      debtId: json['debt_id'] as int,
      amountApplied: (json['amount_applied'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'repayment_id': repaymentId,
    'debt_id': debtId,
    'amount_applied': amountApplied,
  };
}
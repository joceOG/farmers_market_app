part of 'debt_bloc.dart';

abstract class DebtEvent {}

/// Charger les dettes d'un farmer
class DebtLoadRequested extends DebtEvent {
  final String token;
  final int farmerId;
  DebtLoadRequested({required this.token, required this.farmerId});
}

/// Soumettre un remboursement
class RepaymentSubmitted extends DebtEvent {
  final String token;
  final int farmerId;
  final Map<String, dynamic> data;
  RepaymentSubmitted({
    required this.token,
    required this.farmerId,
    required this.data,
  });
}
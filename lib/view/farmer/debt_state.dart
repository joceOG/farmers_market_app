part of 'debt_bloc.dart';

abstract class DebtState {}

class DebtInitial extends DebtState {}

class DebtLoading extends DebtState {}

class DebtLoaded extends DebtState {
  final List<Map<String, dynamic>> debts;
  DebtLoaded({required this.debts});
}

class DebtError extends DebtState {
  final String message;
  DebtError({required this.message});
}

class RepaymentLoading extends DebtState {
  final List<Map<String, dynamic>> debts;
  RepaymentLoading({required this.debts});
}

class RepaymentSuccess extends DebtState {
  final List<Map<String, dynamic>> debts;
  RepaymentSuccess({required this.debts});
}

class RepaymentError extends DebtState {
  final String message;
  final List<Map<String, dynamic>> debts;
  RepaymentError({required this.message, required this.debts});
}
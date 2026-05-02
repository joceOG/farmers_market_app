part of 'dashboard_bloc.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final int totalFarmers;
  final int totalTransactions;
  final int activeCredits;
  final double reimbursedPercent;
  final List<Map<String, dynamic>> recentFarmers;

  DashboardLoaded({
    required this.totalFarmers,
    required this.totalTransactions,
    required this.activeCredits,
    required this.reimbursedPercent,
    required this.recentFarmers,
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError({required this.message});
}
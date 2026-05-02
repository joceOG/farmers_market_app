part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

/// Chargement initial du dashboard
class DashboardLoadRequested extends DashboardEvent {
  final String token;
  DashboardLoadRequested({required this.token});
}

/// Rafraîchissement manuel
class DashboardRefreshRequested extends DashboardEvent {
  final String token;
  DashboardRefreshRequested({required this.token});
}
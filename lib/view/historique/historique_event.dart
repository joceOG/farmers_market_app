part of 'historique_bloc.dart';

abstract class HistoriqueEvent extends Equatable {
  const HistoriqueEvent();
  @override
  List<Object?> get props => [];
}

class HistoriqueLoaded extends HistoriqueEvent {
  final String token;
  const HistoriqueLoaded({required this.token});
  @override
  List<Object?> get props => [token];
}

class HistoriqueFiltreChanged extends HistoriqueEvent {
  // 'Tout' | 'cash' | 'credit'
  final String filtre;
  const HistoriqueFiltreChanged(this.filtre);
  @override
  List<Object?> get props => [filtre];
}

class HistoriquePeriodeChanged extends HistoriqueEvent {
  final String periode;
  const HistoriquePeriodeChanged(this.periode);
  @override
  List<Object?> get props => [periode];
}

class HistoriqueDetailRequested extends HistoriqueEvent {
  final String transactionId;
  final String token;
  const HistoriqueDetailRequested({
    required this.transactionId,
    required this.token,
  });
  @override
  List<Object?> get props => [transactionId, token];
}
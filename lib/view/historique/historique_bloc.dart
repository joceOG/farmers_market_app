import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/api_client.dart';

part 'historique_event.dart';
part 'historique_state.dart';

class HistoriqueBloc extends Bloc<HistoriqueEvent, HistoriqueState> {
  final ApiClient _api;

  HistoriqueBloc({required ApiClient apiClient})
      : _api = apiClient,
        super(HistoriqueInitial()) {
    on<HistoriqueLoaded>(_onLoaded);
    on<HistoriqueFiltreChanged>(_onFiltreChanged);
    on<HistoriquePeriodeChanged>(_onPeriodeChanged);
    on<HistoriqueDetailRequested>(_onDetailRequested);
  }

  // ── Chargement initial ────────────────────────────────────────
  Future<void> _onLoaded(
      HistoriqueLoaded event,
      Emitter<HistoriqueState> emit,
      ) async {
    emit(HistoriqueLoading());
    try {
      // api_client unwrappe déjà data.data → retourne List<dynamic> directement
      final rawList = await _api.get('transactions', token: event.token) as List<dynamic>;

      final transactions = rawList
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();

      emit(_buildSuccess(
        transactions: transactions,
        filtreActif: 'Tout',
        periodeActive: 'Ce mois',
      ));
    } catch (e, stack) {
      debugPrint('HistoriqueBloc error: $e\n$stack');
      emit(HistoriqueError(e.toString()));
    }
  }

  // ── Changement de filtre ──────────────────────────────────────
  void _onFiltreChanged(
      HistoriqueFiltreChanged event,
      Emitter<HistoriqueState> emit,
      ) {
    final current = _currentListeState;
    if (current == null) return;

    emit(_buildSuccess(
      transactions: current.transactions,
      filtreActif: event.filtre,
      periodeActive: current.periodeActive,
    ));
  }

  // ── Changement de période ─────────────────────────────────────
  void _onPeriodeChanged(
      HistoriquePeriodeChanged event,
      Emitter<HistoriqueState> emit,
      ) {
    final current = _currentListeState;
    if (current == null) return;

    emit(_buildSuccess(
      transactions: current.transactions,
      filtreActif: current.filtreActif,
      periodeActive: event.periode,
    ));
  }

  // ── Détail : on cherche dans la liste déjà chargée ────────────
  // (pas de second appel réseau : les items sont déjà dans la liste)
  Future<void> _onDetailRequested(
      HistoriqueDetailRequested event,
      Emitter<HistoriqueState> emit,
      ) async {
    final listeState = _currentListeState;
    if (listeState == null) return;

    emit(HistoriqueDetailLoading());

    try {
      // Cherche dans la liste locale
      final tx = listeState.transactions.firstWhere(
            (t) => t.id == event.transactionId,
      );
      emit(HistoriqueDetailSuccess(detail: tx, listeState: listeState));
    } catch (e) {
      // Si non trouvé (cas rare), on peut faire un appel réseau en fallback
      try {
        final response = await _api.get(
          'transactions/${event.transactionId}',
          token: event.token,
        );
        final Map<String, dynamic> body = response as Map<String, dynamic>;
        // L'endpoint individuel retourne probablement { "data": {...} }
        final data = body['data'] as Map<String, dynamic>? ?? body;
        final tx = Transaction.fromJson(data);
        emit(HistoriqueDetailSuccess(detail: tx, listeState: listeState));
      } catch (e2) {
        emit(HistoriqueDetailError(message: e2.toString(), listeState: listeState));
      }
    }
  }

  // ── Helper ────────────────────────────────────────────────────
  HistoriqueSuccess? get _currentListeState {
    final s = state;
    if (s is HistoriqueSuccess) return s;
    if (s is HistoriqueDetailLoading) return null;
    if (s is HistoriqueDetailSuccess) return s.listeState;
    if (s is HistoriqueDetailError)   return s.listeState;
    return null;
  }

  HistoriqueSuccess _buildSuccess({
    required List<Transaction> transactions,
    required String filtreActif,
    required String periodeActive,
  }) {
    final filtrees = filtreActif == 'Tout'
        ? transactions
        : transactions
        .where((t) => t.mode.toLowerCase() == filtreActif.toLowerCase())
        .toList();

    final total = filtrees.fold<double>(0, (sum, t) => sum + t.montant);

    return HistoriqueSuccess(
      transactions: transactions,
      transactionsFiltrees: filtrees,
      filtreActif: filtreActif,
      periodeActive: periodeActive,
      totalMontant: total,
    );
  }
}
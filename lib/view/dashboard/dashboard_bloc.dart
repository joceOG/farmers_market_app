import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/api_client.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ApiClient _apiClient;

  DashboardBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(
      DashboardLoadRequested event,
      Emitter<DashboardState> emit,
      ) async {
    emit(DashboardLoading());
    await _fetchData(event.token, emit);
  }

  Future<void> _onRefresh(
      DashboardRefreshRequested event,
      Emitter<DashboardState> emit,
      ) async {
    await _fetchData(event.token, emit);
  }

  Future<void> _fetchData(String token, Emitter<DashboardState> emit) async {
    try {
      final results = await Future.wait([
        _apiClient.get('farmers', token: token),
        _apiClient.get('transactions', token: token),
      ]);

      // ✅ Ajoute ces prints ici
   //   print('=== FARMERS ===');
   //   print(results[0]);
    //  print('TYPE farmers: ${results[0].runtimeType}');

  //    print('=== TRANSACTIONS ===');
    //  print(results[1]);
     // print('TYPE transactions: ${results[1].runtimeType}');

      final farmers = results[0] as List<dynamic>;
      final transactions = results[1] as List<dynamic>;

      // ── Crédits actifs = transactions payment_method == 'credit'
      //    ET credited_amount > 0 (non encore remboursées)
      final creditTransactions = transactions
          .where((t) => t['payment_method']?.toString() == 'credit')
          .toList();

      final activeCredits = creditTransactions
          .where((t) =>
      (double.tryParse(t['credited_amount']?.toString() ?? '0') ?? 0) > 0)
          .length;

      final reimbursedCount = creditTransactions
          .where((t) =>
      (double.tryParse(t['credited_amount']?.toString() ?? '0') ?? 0) == 0)
          .length;

      final reimbursedPercent = creditTransactions.isEmpty
          ? 0.0
          : (reimbursedCount / creditTransactions.length * 100);

      // ── 5 farmers les plus récents triés par created_at desc
      final sortedFarmers = List<Map<String, dynamic>>.from(
        farmers.map((f) => f as Map<String, dynamic>),
      );
      sortedFarmers.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime(0);
        final dateB =
            DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime(0);
        return dateB.compareTo(dateA);
      });

      emit(DashboardLoaded(
        totalFarmers: farmers.length,
        totalTransactions: transactions.length,
        activeCredits: activeCredits,
        reimbursedPercent: reimbursedPercent,
        recentFarmers: sortedFarmers.take(5).toList(),
      ));
    } on Exception catch (e) {
      emit(DashboardError(
        message: e.toString().replaceFirst('Exception: ', ''),
      ));
    } catch (_) {
      emit(DashboardError(
          message: 'Erreur lors du chargement du tableau de bord'));
    }
  }
}
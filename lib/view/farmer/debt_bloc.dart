import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/api_client.dart';

part 'debt_event.dart';
part 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final ApiClient _apiClient;

  DebtBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(DebtInitial()) {
    on<DebtLoadRequested>(_onLoad);
    on<RepaymentSubmitted>(_onRepayment);
  }

  Future<void> _onLoad(DebtLoadRequested event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    try {
      // On appelle l'API directement sans passer par api_client.get()
      // car la structure { data: { farmer, debts, total_outstanding } } est spécifique
      final raw = await _apiClient.getRaw(
        'farmers/${event.farmerId}/debts',
        token: event.token,
      );

      // Structure : { data: { farmer: {...}, debts: [...], total_outstanding: ... } }
      final body = raw is Map ? raw : <String, dynamic>{};
      final dataNode = body['data'];

      List<Map<String, dynamic>> debts = [];

      if (dataNode is Map) {
        final debtsRaw = dataNode['debts'];
        if (debtsRaw is List) {
          debts = debtsRaw.map((e) => e as Map<String, dynamic>).toList();
        }
      } else if (dataNode is List) {
        // fallback si l'API change
        debts = dataNode.map((e) => e as Map<String, dynamic>).toList();
      }

      emit(DebtLoaded(debts: debts));
    } on Exception catch (e) {
      emit(DebtError(message: e.toString().replaceFirst('Exception: ', '')));
    } catch (_) {
      emit(DebtError(message: 'Erreur lors du chargement des dettes'));
    }
  }

  Future<void> _onRepayment(RepaymentSubmitted event, Emitter<DebtState> emit) async {
    final current = state;
    List<Map<String, dynamic>> debts = [];
    if (current is DebtLoaded) debts = current.debts;

    emit(RepaymentLoading(debts: debts));
    try {
      await _apiClient.post(
        'repayments',
        token: event.token,
        body: event.data,
      );
      // Recharger les dettes après remboursement
      final raw = await _apiClient.getRaw(
        'farmers/${event.farmerId}/debts',
        token: event.token,
      );
      final body = raw is Map ? raw : <String, dynamic>{};
      final dataNode = body['data'];
      List<Map<String, dynamic>> updatedDebts = [];
      if (dataNode is Map) {
        final debtsRaw = dataNode['debts'];
        if (debtsRaw is List) {
          updatedDebts = debtsRaw.map((e) => e as Map<String, dynamic>).toList();
        }
      } else if (dataNode is List) {
        updatedDebts = dataNode.map((e) => e as Map<String, dynamic>).toList();
      }
      emit(RepaymentSuccess(debts: updatedDebts));
    } on Exception catch (e) {
      emit(RepaymentError(
        message: e.toString().replaceFirst('Exception: ', ''),
        debts: debts,
      ));
    } catch (_) {
      emit(RepaymentError(
        message: 'Erreur lors du remboursement',
        debts: debts,
      ));
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is List) return raw.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }
}
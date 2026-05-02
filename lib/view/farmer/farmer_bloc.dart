import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/api_client.dart';

part 'farmer_event.dart';
part 'farmer_state.dart';

class FarmerBloc extends Bloc<FarmerEvent, FarmerState> {
  final ApiClient _apiClient;

  FarmerBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(FarmerInitial()) {
    on<FarmerLoadRequested>(_onLoad);
    on<FarmerSearchChanged>(_onSearch);
    on<FarmerCreateRequested>(_onCreate);
  }

  Future<void> _onLoad(
      FarmerLoadRequested event,
      Emitter<FarmerState> emit,
      ) async {
    emit(FarmerLoading());
    try {
      final raw = await _apiClient.get('farmers', token: event.token);
      final farmers = _parseList(raw);
      emit(FarmerLoaded(
        allFarmers: farmers,
        filteredFarmers: farmers,
      ));
    } on Exception catch (e) {
      emit(FarmerError(message: e.toString().replaceFirst('Exception: ', '')));
    } catch (_) {
      emit(FarmerError(message: 'Erreur lors du chargement des farmers'));
    }
  }

  void _onSearch(
      FarmerSearchChanged event,
      Emitter<FarmerState> emit,
      ) {
    final current = state;
    List<Map<String, dynamic>> all = [];

    if (current is FarmerLoaded) all = current.allFarmers;
    if (current is FarmerCreateSuccess) all = current.allFarmers;

    final q = event.query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? all
        : all.where((f) {
      final name =
      '${f['firstname'] ?? ''} ${f['lastname'] ?? ''}'.toLowerCase();
      final id = (f['identifier'] ?? '').toString().toLowerCase();
      final phone = (f['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q) || phone.contains(q);
    }).toList();

    emit(FarmerLoaded(
      allFarmers: all,
      filteredFarmers: filtered,
      query: q,
    ));
  }

  Future<void> _onCreate(
      FarmerCreateRequested event,
      Emitter<FarmerState> emit,
      ) async {
    final current = state;
    List<Map<String, dynamic>> all = [];
    List<Map<String, dynamic>> filtered = [];

    if (current is FarmerLoaded) {
      all = current.allFarmers;
      filtered = current.filteredFarmers;
    }

    emit(FarmerCreating(allFarmers: all, filteredFarmers: filtered));

    try {
      final result =
      await _apiClient.post('farmers', token: event.token, body: event.data);

      // Le nouveau farmer retourné par Laravel
      final newFarmer = (result['data'] ?? result) as Map<String, dynamic>;

      final updatedAll = [newFarmer, ...all];
      final updatedFiltered = [newFarmer, ...filtered];

      emit(FarmerCreateSuccess(
        allFarmers: updatedAll,
        filteredFarmers: updatedFiltered,
      ));
    } on Exception catch (e) {
      emit(FarmerCreateError(
        message: e.toString().replaceFirst('Exception: ', ''),
        allFarmers: all,
        filteredFarmers: filtered,
      ));
    } catch (_) {
      emit(FarmerCreateError(
        message: 'Erreur lors de la création du farmer',
        allFarmers: all,
        filteredFarmers: filtered,
      ));
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is List) return raw.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }
}
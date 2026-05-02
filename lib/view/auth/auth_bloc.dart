import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/api_client.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient;

  // Stockage temporaire en attente de confirmation
  String? _pendingToken;
  Map<String, dynamic>? _pendingUser;

  AuthBloc({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<AdminModeConfirmed>(_onAdminConfirmed);
    on<AdminModeDeclined>(_onAdminDeclined);
    on<SuperviseurModeConfirmed>(_onSuperviseurConfirmed);
    on<SuperviseurModeDeclined>(_onSuperviseurDeclined);
  }

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final data = await _apiClient.login(
        username: event.username,
        password: event.password,
      );

      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      final role = (user['role'] as String? ?? 'operator').toLowerCase();
      print('USER RECU: $user'); // ← ajoute ça
      print('USERNAME: ${user['username']}'); // ← et ç


      _pendingToken = token;
      _pendingUser = user;

      if (role == 'admin') {
        emit(AuthAdminConfirmation(token: token, user: user));
      } else if (role == 'superviseur') {
        emit(AuthSuperviseurConfirmation(token: token, user: user));
      } else {
        emit(AuthSuccess(token: token, user: user, role: 'operator'));
      }
    } on Exception catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('Exception: ', '')));
    } catch (_) {
      emit(AuthFailure(message: 'Une erreur inattendue est survenue'));
    }
  }

  void _onAdminConfirmed(AdminModeConfirmed event, Emitter<AuthState> emit) {
    emit(AuthSuccess(token: _pendingToken!, user: _pendingUser!, role: 'admin'));
  }

  void _onAdminDeclined(AdminModeDeclined event, Emitter<AuthState> emit) {
    emit(AuthSuccess(token: _pendingToken!, user: _pendingUser!, role: 'operator'));
  }

  void _onSuperviseurConfirmed(SuperviseurModeConfirmed event, Emitter<AuthState> emit) {
    emit(AuthSuccess(token: _pendingToken!, user: _pendingUser!, role: 'superviseur'));
  }

  void _onSuperviseurDeclined(SuperviseurModeDeclined event, Emitter<AuthState> emit) {
    emit(AuthSuccess(token: _pendingToken!, user: _pendingUser!, role: 'operator'));
  }
}
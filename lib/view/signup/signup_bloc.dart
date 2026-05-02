import 'package:flutter_bloc/flutter_bloc.dart';
import 'signup_event.dart';
import 'signup_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc() : super(SignUpInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event,
      Emitter<SignUpState> emit,
      ) async {
    emit(SignUpLoading());

    if (event.password != event.confirmPassword) {
      emit(SignUpFailure(message: 'Les mots de passe ne correspondent pas'));
      return;
    }

    if (event.supervisorCode.isEmpty) {
      emit(SignUpFailure(message: 'Code superviseur requis'));
      return;
    }

    try {
      // TODO: remplacer par appel API réel
      await Future.delayed(const Duration(seconds: 1));
      emit(SignUpSuccess());
    } catch (e) {
      emit(SignUpFailure(message: e.toString()));
    }
  }
}
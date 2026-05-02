abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String token;
  final Map<String, dynamic> user;
  final String role; // 'operator', 'admin', 'superviseur'

  AuthSuccess({required this.token, required this.user, required this.role});
}

class AuthAdminConfirmation extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  AuthAdminConfirmation({required this.token, required this.user});
}

class AuthSuperviseurConfirmation extends AuthState {
  final String token;
  final Map<String, dynamic> user;

  AuthSuperviseurConfirmation({required this.token, required this.user});
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure({required this.message});
}
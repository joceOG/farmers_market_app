abstract class SignUpEvent {}

class SignUpRequested extends SignUpEvent {
  final String username;
  final String password;
  final String confirmPassword;
  final String supervisorCode;

  SignUpRequested({
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.supervisorCode,
  });
}
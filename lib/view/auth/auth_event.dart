abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested({required this.username, required this.password});
}

class AdminModeConfirmed extends AuthEvent {}   // "Oui" sur le dialog Admin
class AdminModeDeclined extends AuthEvent {     // "Non" → reste operator
  final String token;
  final Map<String, dynamic> user;
  AdminModeDeclined({required this.token, required this.user});
}

class SuperviseurModeConfirmed extends AuthEvent {}
class SuperviseurModeDeclined extends AuthEvent {
  final String token;
  final Map<String, dynamic> user;
  SuperviseurModeDeclined({required this.token, required this.user});
}
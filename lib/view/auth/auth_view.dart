import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'auth_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

const Color kGreen = Color(0xFF2D6A4F);

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _showRoleDialog(
      BuildContext context, {
        required String title,
        required String message,
        required VoidCallback onConfirmed,
        required VoidCallback onDeclined,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeclined();
            },
            child: const Text('Non, continuer',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirmed();
            },
            child:
            const Text('Oui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
      const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF5F5F0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: Color(0xFFCCCCBB), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        const BorderSide(color: Color(0xFFCCCCBB), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kGreen, width: 1.5),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  /// Construit le nom d'affichage depuis l'objet user retourné par l'API
  /// Adapte les clés selon ta réponse réelle (/api/login → user.name ou user.firstname+lastname)
  String _buildDisplayName(Map<String, dynamic> user) {
    return user['username'] as String? ?? 'Operator';
  }

  /// Navigation vers le bon dashboard en passant token + username en extra
  void _navigateToDashboard(
      BuildContext context,
      AuthSuccess state,
      ) {
    final displayName = _buildDisplayName(state.user);
    final extra = {'token': state.token, 'username': displayName};

    switch (state.role) {
      case 'admin':
        context.go('/dashboard-admin', extra: extra);
      case 'superviseur':
        context.go('/dashboard-superviseur', extra: extra);
      default:
        context.go('/dashboard', extra: extra);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAdminConfirmation) {
            _showRoleDialog(
              context,
              title: 'Mode Administrateur',
              message: 'Voulez-vous vous connecter en mode Admin ?',
              onConfirmed: () =>
                  context.read<AuthBloc>().add(AdminModeConfirmed()),
              onDeclined: () => context.read<AuthBloc>().add(
                AdminModeDeclined(
                    token: state.token, user: state.user),
              ),
            );
          } else if (state is AuthSuperviseurConfirmation) {
            _showRoleDialog(
              context,
              title: 'Mode Superviseur',
              message:
              'Voulez-vous vous connecter en mode Superviseur ?',
              onConfirmed: () => context
                  .read<AuthBloc>()
                  .add(SuperviseurModeConfirmed()),
              onDeclined: () => context.read<AuthBloc>().add(
                SuperviseurModeDeclined(
                    token: state.token, user: state.user),
              ),
            );
          } else if (state is AuthSuccess) {
            // ✅ Modification : on passe token + username via extra
            _navigateToDashboard(context, state);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints:
                    const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/farmer_icon.png',
                              height: 80,
                              width: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Bienvenue',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Connectez-vous',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 36),

                        const Text(
                          "Nom d'utilisateur",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          decoration:
                          _fieldDecoration('Ex : operator1'),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Mot de passe',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          decoration:
                          _fieldDecoration('••••••••').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                    () => _obscurePassword =
                                !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                              context
                                  .read<AuthBloc>()
                                  .add(
                                LoginRequested(
                                  username:
                                  _usernameController
                                      .text
                                      .trim(),
                                  password:
                                  _passwordController
                                      .text
                                      .trim(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: state is AuthLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
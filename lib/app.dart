import 'package:farmers_market_app/view/auth/auth_view.dart';
import 'package:farmers_market_app/view/dashboard/dashboard_admin_view.dart';
import 'package:farmers_market_app/view/dashboard/dashboard_view.dart';
import 'package:farmers_market_app/view/signup/signup_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Farmers Market",
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: "/",
            builder: (context, state) => const AuthView(),
          ),
          GoRoute(
            path: "/signup",
            builder: (context, state) => const SignUpView(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return DashboardView(
                token: extra['token'] as String,
                username: extra['username'] as String,
              );
            },
          ),
          GoRoute(
              path: '/dashboard-admin',
              builder: (_, __) => const DashboardAdminView()),
          GoRoute(
              path: '/dashboard-superviseur',
              builder: (_, __) => const DashboardSuperviseurView()),
        ],
      ),
    );
  }
}

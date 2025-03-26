import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/restaurants/presentation/pages/restaurant_list_page.dart';
import '../../features/restaurants/presentation/pages/restaurant_detail_page.dart';
import '../../features/restaurants/presentation/pages/restaurant_form_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/restaurants',
        builder: (context, state) => const RestaurantListPage(),
      ),
      GoRoute(
        path: '/restaurants/:id',
        builder: (context, state) => RestaurantDetailPage(
          restaurantId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/restaurants/new',
        builder: (context, state) => const RestaurantFormPage(),
      ),
      GoRoute(
        path: '/restaurants/:id/edit',
        builder: (context, state) => RestaurantFormPage(
          restaurantId: state.pathParameters['id'],
        ),
      ),
    ],
  );
});

class AppRouter {
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
} 
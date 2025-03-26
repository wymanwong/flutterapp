import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/reservations/presentation/pages/reservations_page.dart';
import '../../features/restaurants/presentation/pages/restaurants_page.dart';
import '../../features/users/presentation/pages/users_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _calculateSelectedIndex(state),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: 'Restaurants',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Reservations',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Users',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/restaurants',
            builder: (context, state) => const RestaurantsPage(),
          ),
          GoRoute(
            path: '/reservations',
            builder: (context, state) => const ReservationsPage(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersPage(),
          ),
        ],
      ),
    ],
  );
});

int _calculateSelectedIndex(GoRouterState state) {
  final String location = state.location;
  if (location.startsWith('/dashboard')) {
    return 0;
  }
  if (location.startsWith('/restaurants')) {
    return 1;
  }
  if (location.startsWith('/reservations')) {
    return 2;
  }
  if (location.startsWith('/users')) {
    return 3;
  }
  return 0;
}

void _onItemTapped(int index, BuildContext context) {
  switch (index) {
    case 0:
      context.go('/dashboard');
      break;
    case 1:
      context.go('/restaurants');
      break;
    case 2:
      context.go('/reservations');
      break;
    case 3:
      context.go('/users');
      break;
    default:
      context.go('/dashboard');
  }
} 
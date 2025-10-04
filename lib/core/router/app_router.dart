import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// Coordinates global navigation based on authentication state.
class AppRouter {
  AppRouter()
    : _authRepository = AuthRepository.instance,
      // Rebuild the router whenever the authentication stream changes.
      _refreshListenable = _StreamRouterRefresh(
        AuthRepository.instance.authStateChanges,
      );

  final AuthRepository _authRepository;
  final _StreamRouterRefresh _refreshListenable;

  /// The single GoRouter instance used by the app shell.
  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _refreshListenable,
    // Gate destinations according to the session and attempted route.
    redirect: (context, state) {
      final session = _authRepository.currentSession;
      final loggingIn = state.uri.path == '/login';
      final signingUp = state.uri.path == '/signup';
      final atRoot = state.uri.path.isEmpty || state.uri.path == '/';

      if (session == null) {
        // Unauthenticated visitors may reach the auth screens only.
        if (loggingIn || signingUp) {
          return null;
        }
        return '/login';
      }

      // Authenticated users land on the About page unless a deeper route is requested.
      if (loggingIn || signingUp || atRoot) {
        return '/about';
      }

      return null;
    },
    routes: <RouteBase>[
      // Public authentication flow.
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      // Primary landing page once the user is authenticated.
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      // Data-rich dashboard experience accessible after sign-in.
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}

/// Bridges a stream into a ChangeNotifier so GoRouter can listen for changes.
class _StreamRouterRefresh extends ChangeNotifier {
  _StreamRouterRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

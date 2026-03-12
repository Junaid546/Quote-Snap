import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/new_quote/new_quote_step1_screen.dart';
import '../../presentation/screens/new_quote/new_quote_step2_screen.dart';
import '../../presentation/screens/new_quote/new_quote_step3_screen.dart';
import '../../presentation/screens/quotes/quote_history_screen.dart';
import '../../presentation/screens/quotes/quote_detail_screen.dart';

import '../../presentation/screens/clients/client_directory_screen.dart';
import '../../presentation/screens/clients/client_detail_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/screens/subscription/upgrade_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final shellNavigatorQuotesKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellQuotes',
);
final shellNavigatorClientsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellClients',
);
final shellNavigatorStatsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellStats',
);
final shellNavigatorSettingsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellSettings',
);

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the auth stream for router refresh
  final authListenable = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAtSplash = state.matchedLocation == '/splash';
      final isAtOnboarding = state.matchedLocation == '/onboarding';
      final isAtLogin = state.matchedLocation == '/login';
      final isPublicRoute = isAtSplash || isAtOnboarding || isAtLogin;

      // If user is logged in and is at a public route, send to dashboard
      if (user != null && isPublicRoute && !isAtSplash) {
        return '/home/dashboard';
      }

      // If user is not logged in and is trying to access a protected route
      if (user == null && !isPublicRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) => const UpgradeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Return the AppShell widget which contains the BottomNavigationBar
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Quotes Branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorQuotesKey,
            routes: [
              GoRoute(
                path: '/home/quotes',
                builder: (context, state) => const QuoteHistoryScreen(),
              ),
            ],
          ),
          // Clients Branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorClientsKey,
            routes: [
              GoRoute(
                path: '/home/clients',
                builder: (context, state) => const ClientDirectoryScreen(),
              ),
            ],
          ),
          // Stats Branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorStatsKey,
            routes: [
              GoRoute(
                path: '/home/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          // Settings Branch
          StatefulShellBranch(
            navigatorKey: shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/home/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/new-quote/step1',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NewQuoteStep1Screen(),
      ),
      GoRoute(
        path: '/new-quote/step2',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NewQuoteStep2Screen(),
      ),
      GoRoute(
        path: '/new-quote/step3',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NewQuoteStep3Screen(),
      ),
      GoRoute(
        path: '/quote-detail/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            QuoteDetailScreen(quoteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/client-detail/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ClientDetailScreen(clientId: state.pathParameters['id']!),
      ),
    ],
  );
});

// ─── Router Refresh Listenable ─────────────────────────────────────────────────

final _routerRefreshProvider = Provider<_AuthListenable>((ref) {
  return _AuthListenable(FirebaseAuth.instance.authStateChanges());
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Stream<User?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

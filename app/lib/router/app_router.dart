import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/landing/screens/landing_screen.dart';
import '../features/tree/screens/tree_view_screen.dart';
import '../features/tree/screens/add_member_screen.dart';
import '../features/profile/screens/person_detail_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/invite/screens/invite_screen.dart';
import '../features/connection/screens/connection_finder_screen.dart';
import '../features/merge/screens/merge_review_screen.dart';
import '../features/forum/screens/forum_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/stats/screens/statistics_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/error_logs_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/admin/screens/admin_analytics_screen.dart';
import '../widgets/app_shell.dart';

// Auth change notifier for GoRouter
class AuthNotifier extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;

  AuthNotifier() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final notifier = AuthNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/landing',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Use currentUser instead of currentSession for more reliable auth checking
      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = user != null;
      final isLoginRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isLandingRoute = state.matchedLocation == '/landing';
      final isInviteRoute = state.matchedLocation.startsWith('/invite');
      final isResetPasswordRoute = state.matchedLocation == '/reset-password';

      debugPrint('🔄 Router redirect: ${state.matchedLocation}, isLoggedIn: $isLoggedIn, user: ${user?.email ?? "null"}, hasSession: ${session != null}');

      // Allow landing, login, signup, reset-password, and invite routes without auth
      if (isLandingRoute || isLoginRoute || isInviteRoute || isResetPasswordRoute) return null;

      // If not logged in and trying to access protected route, redirect to login
      if (!isLoggedIn) return '/login';

      // If logged in and on login page, redirect to tree
      if (isLoggedIn && isLoginRoute) return '/tree';

      return null;
    },
    routes: [
      // Landing Page (no shell)
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),

      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main app shell with sidebar navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Tree
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tree',
                builder: (context, state) => const TreeViewScreen(),
                routes: [
                  GoRoute(
                    path: 'add-member',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return AddMemberScreen(
                        relativePersonId: extra?['relativePersonId'] as String?,
                        relationshipType: extra?['relationshipType'] as String?,
                        gender: extra?['gender'] as String?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Branch 2: Connection Finder
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/connection',
                builder: (context, state) {
                  final targetUsername = state.uri.queryParameters['target'];
                  return ConnectionFinderScreen(targetUsername: targetUsername);
                },
              ),
            ],
          ),
          // Branch 3: Invite
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invite',
                builder: (context, state) {
                  final token = state.uri.queryParameters['token'];
                  return InviteScreen(token: token);
                },
              ),
            ],
          ),
          // Branch 4: Forum
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/forum',
                builder: (context, state) => const ForumScreen(),
              ),
            ],
          ),
          // Branch 5: Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Branch 6: Statistics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Legacy route - redirect to tree
      GoRoute(
        path: '/',
        redirect: (context, state) => '/tree',
      ),

      // Detail routes (shown inside the shell context)
      GoRoute(
        path: '/person/:id',
        builder: (context, state) => PersonDetailScreen(
          personId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/edit-profile/:id',
        builder: (context, state) => EditProfileScreen(
          personId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/merge/:id',
        builder: (context, state) => MergeReviewScreen(
          mergeRequestId: state.pathParameters['id']!,
        ),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/errors',
        builder: (context, state) => const ErrorLogsScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

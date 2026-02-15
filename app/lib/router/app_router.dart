import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/tree/screens/tree_view_screen.dart';
import '../features/tree/screens/add_member_screen.dart';
import '../features/profile/screens/person_detail_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/invite/screens/invite_screen.dart';
import '../features/merge/screens/merge_review_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoginRoute = state.matchedLocation == '/login';
      final isInviteRoute = state.matchedLocation.startsWith('/invite');

      // Allow invite route without auth
      if (isInviteRoute) return null;

      // If not logged in, redirect to login
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // If logged in and on login page, redirect to home
      if (isLoggedIn && isLoginRoute) return '/';

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Profile setup (first-time)
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Home - Tree View
      GoRoute(
        path: '/',
        builder: (context, state) => const TreeViewScreen(),
        routes: [
          // Add family member
          GoRoute(
            path: 'add-member',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddMemberScreen(
                relativePersonId: extra?['relativePersonId'] as String?,
                relationshipType: extra?['relationshipType'] as String?,
              );
            },
          ),
        ],
      ),

      // Person detail
      GoRoute(
        path: '/person/:id',
        builder: (context, state) => PersonDetailScreen(
          personId: state.pathParameters['id']!,
        ),
      ),

      // Edit profile
      GoRoute(
        path: '/edit-profile/:id',
        builder: (context, state) => EditProfileScreen(
          personId: state.pathParameters['id']!,
        ),
      ),

      // Search
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Invite
      GoRoute(
        path: '/invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return InviteScreen(token: token);
        },
      ),

      // Merge review
      GoRoute(
        path: '/merge/:id',
        builder: (context, state) => MergeReviewScreen(
          mergeRequestId: state.pathParameters['id']!,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});

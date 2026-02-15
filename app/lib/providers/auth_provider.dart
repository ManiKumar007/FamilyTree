import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

/// Auth state provider - listens to Supabase auth changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).value;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Current person profile provider
/// Fetches the Person record for the current logged-in user
final currentPersonProvider = FutureProvider<Person?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  // TODO: Fetch person from API
  // For now, return null until we implement the API call
  return null;
});

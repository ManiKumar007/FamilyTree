import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/models.dart';

// ==================== AUTH STATE ====================

/// Watches Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user (null if not logged in)
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// ==================== PROFILE ====================

/// Current user's person profile
final myProfileProvider = FutureProvider<Person?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    print('⚠️ No user logged in, cannot fetch profile');
    return null;
  }

  final apiService = ref.watch(apiServiceProvider);
  try {
    final profile = await apiService.getMyProfile();
    print('✅ Profile fetched successfully: ${profile?.name}');
    return profile;
  } catch (e) {
    print('❌ Error fetching profile: $e');
    return null;
  }
});

// ==================== FAMILY TREE ====================

/// Family tree data
final familyTreeProvider = FutureProvider<TreeResponse?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    print('⚠️ No user logged in, cannot fetch tree');
    return null;
  }

  final apiService = ref.watch(apiServiceProvider);
  print('🌲 Fetching family tree...');
  final tree = await apiService.getMyTree();
  final totalRelationships = tree.nodes.fold<int>(0, (sum, node) => sum + node.relationships.length);
  print('✅ Family tree fetched: ${tree.nodes.length} nodes, $totalRelationships relationships');
  return tree;
});

// ==================== MERGE REQUESTS ====================

/// Pending merge requests
final pendingMergesProvider = FutureProvider<List<MergeRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getPendingMergeRequests();
});

// ==================== SEARCH ====================

/// Search state
class SearchState {
  final String query;
  final String? occupation;
  final String? maritalStatus;
  final int depth;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.occupation,
    this.maritalStatus,
    this.depth = 3,
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    String? occupation,
    String? maritalStatus,
    int? depth,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      occupation: occupation ?? this.occupation,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      depth: depth ?? this.depth,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _apiService;
  // ignore: unused_field
  final AuthService _authService;

  SearchNotifier(this._apiService, this._authService) : super(const SearchState());

  Future<void> search({
    String? query,
    String? occupation,
    String? maritalStatus,
    int? depth,
  }) async {
    state = state.copyWith(
      query: query ?? state.query,
      occupation: occupation,
      maritalStatus: maritalStatus,
      depth: depth ?? state.depth,
      isLoading: true,
      error: null,
    );

    try {
      // Optionally refresh session before searching (non-blocking)
      print('🔍 Searching with query="${state.query}", occupation="${state.occupation}", depth=${state.depth}');
      
      final results = await _apiService.search(
        query: state.query.isEmpty ? null : state.query,
        occupation: state.occupation,
        maritalStatus: state.maritalStatus,
        depth: state.depth,
      );
      print('✅ Search returned ${results.length} results');
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      print('❌ Search error: $e');
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Better error messages
      if (errorMessage.contains('Service unavailable') || errorMessage.contains('Cannot connect') || errorMessage.contains('503')) {
        errorMessage = 'Server is temporarily unavailable. Please try again in a moment or contact support.';
      } else if (errorMessage.contains('Invalid or expired token') && !errorMessage.contains('Service unavailable')) {
        errorMessage = 'Your session has expired. Please sign in again to continue searching.';
      } else if (errorMessage.contains('Profile not found')) {
        errorMessage = 'Please complete your profile setup to search your family network.';
      } else if (errorMessage.contains('Network') || errorMessage.contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return SearchNotifier(apiService, authService);
});

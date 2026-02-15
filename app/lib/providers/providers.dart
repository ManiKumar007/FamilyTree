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
  if (user == null) return null;

  final apiService = ref.watch(apiServiceProvider);
  try {
    return await apiService.getMyProfile();
  } catch (_) {
    return null;
  }
});

// ==================== FAMILY TREE ====================

/// Family tree data
final familyTreeProvider = FutureProvider<TreeResponse?>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null) return null;

  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMyTree();
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

  SearchNotifier(this._apiService) : super(const SearchState());

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
      final results = await _apiService.search(
        query: state.query.isEmpty ? null : state.query,
        occupation: state.occupation,
        maritalStatus: state.maritalStatus,
        depth: state.depth,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SearchNotifier(apiService);
});

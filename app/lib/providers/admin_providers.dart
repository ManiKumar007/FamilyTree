import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_service.dart';

// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getDashboardStats();
});

// User Growth Provider
final userGrowthProvider = FutureProvider.family<List<UserGrowthData>, int>((ref, days) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getUserGrowth(days: days);
});

// Tree Distribution Provider
final treeDistributionProvider = FutureProvider<List<TreeSizeDistribution>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getTreeDistribution();
});

// Active Users Provider
final activeUsersProvider = FutureProvider<List<ActiveUser>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getActiveUsers();
});

// Error Logs Provider with State
class ErrorLogsState {
  final List<ErrorLog> errors;
  final Pagination pagination;
  final String? filterType;
  final String? filterSeverity;
  final bool isLoading;

  ErrorLogsState({
    required this.errors,
    required this.pagination,
    this.filterType,
    this.filterSeverity,
    this.isLoading = false,
  });

  ErrorLogsState copyWith({
    List<ErrorLog>? errors,
    Pagination? pagination,
    String? filterType,
    String? filterSeverity,
    bool? isLoading,
  }) {
    return ErrorLogsState(
      errors: errors ?? this.errors,
      pagination: pagination ?? this.pagination,
      filterType: filterType ?? this.filterType,
      filterSeverity: filterSeverity ?? this.filterSeverity,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ErrorLogsNotifier extends StateNotifier<ErrorLogsState> {
  final AdminService _adminService;

  ErrorLogsNotifier(this._adminService) : super(ErrorLogsState(
    errors: [],
    pagination: Pagination(page: 1, pageSize: 50, total: 0, totalPages: 0),
  )) {
    loadErrors();
  }

  Future<void> loadErrors({int? page}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _adminService.getErrorLogs(
        page: page ?? state.pagination.page,
        type: state.filterType,
        severity: state.filterSeverity,
      );
      state = state.copyWith(
        errors: response.errors,
        pagination: response.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> setFilters({String? type, String? severity}) async {
    state = state.copyWith(
      filterType: type,
      filterSeverity: severity,
    );
    await loadErrors(page: 1);
  }

  Future<void> resolveError(String errorId) async {
    await _adminService.resolveError(errorId);
    await loadErrors(); // Reload to show updated status
  }
}

final errorLogsProvider = StateNotifierProvider<ErrorLogsNotifier, ErrorLogsState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return ErrorLogsNotifier(adminService);
});

// Error Stats Provider
final errorStatsProvider = FutureProvider.family<List<ErrorSummary>, int>((ref, days) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getErrorStats(days: days);
});

// Users Management Provider
class UsersState {
  final List<UserMetadata> users;
  final Pagination pagination;
  final String? roleFilter;
  final bool isLoading;

  UsersState({
    required this.users,
    required this.pagination,
    this.roleFilter,
    this.isLoading = false,
  });

  UsersState copyWith({
    List<UserMetadata>? users,
    Pagination? pagination,
    String? roleFilter,
    bool? isLoading,
  }) {
    return UsersState(
      users: users ?? this.users,
      pagination: pagination ?? this.pagination,
      roleFilter: roleFilter ?? this.roleFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UsersNotifier extends StateNotifier<UsersState> {
  final AdminService _adminService;

  UsersNotifier(this._adminService) : super(UsersState(
    users: [],
    pagination: Pagination(page: 1, pageSize: 20, total: 0, totalPages: 0),
  )) {
    loadUsers();
  }

  Future<void> loadUsers({int? page}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _adminService.getUsers(
        page: page ?? state.pagination.page,
        role: state.roleFilter,
      );
      state = state.copyWith(
        users: response.users,
        pagination: response.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> setRoleFilter(String? role) async {
    state = state.copyWith(roleFilter: role);
    await loadUsers(page: 1);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _adminService.updateUserRole(userId, role);
    await loadUsers(); // Reload to show updated role
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _adminService.updateUserStatus(userId, isActive);
    await loadUsers(); // Reload to show updated status
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return UsersNotifier(adminService);
});

// Audit Logs Provider
final auditLogsProvider = FutureProvider.family<AuditLogsResponse, int>((ref, page) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getAuditLogs(page: page);
});

// System Health Provider
final systemHealthProvider = FutureProvider<SystemHealth>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getSystemHealth();
});

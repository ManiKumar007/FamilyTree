import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import 'auth_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AdminService(authService);
});

class AdminService {
  final AuthService _authService;
  
  AdminService(this._authService);

  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  // ==================== DASHBOARD STATS ====================

  Future<DashboardStats> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/stats'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load stats');
    return DashboardStats.fromJson(jsonDecode(response.body));
  }

  // ==================== ANALYTICS ====================

  Future<List<UserGrowthData>> getUserGrowth({int days = 30}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/analytics/growth?days=$days'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load growth data');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => UserGrowthData.fromJson(json)).toList();
  }

  Future<List<TreeSizeDistribution>> getTreeDistribution() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/analytics/tree-distribution'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load tree distribution');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => TreeSizeDistribution.fromJson(json)).toList();
  }

  Future<List<ActiveUser>> getActiveUsers({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/analytics/active-users?limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load active users');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ActiveUser.fromJson(json)).toList();
  }

  // ==================== ERROR LOGS ====================

  Future<ErrorLogsResponse> getErrorLogs({
    int page = 1,
    int pageSize = 50,
    String? type,
    String? severity,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
    };
    final uri = Uri.parse('$_baseUrl/admin/errors').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to load errors');
    return ErrorLogsResponse.fromJson(jsonDecode(response.body));
  }

  Future<List<ErrorSummary>> getErrorStats({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/errors/stats?days=$days'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load error stats');
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ErrorSummary.fromJson(json)).toList();
  }

  Future<void> resolveError(String errorId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/errors/$errorId/resolve'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to resolve error');
  }

  // ==================== USER MANAGEMENT ====================

  Future<UsersResponse> getUsers({
    int page = 1,
    int pageSize = 20,
    String? role,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (role != null) 'role': role,
    };
    final uri = Uri.parse('$_baseUrl/admin/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to load users');
    return UsersResponse.fromJson(jsonDecode(response.body));
  }

  Future<void> updateUserRole(String userId, String role) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update role');
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/admin/users/$userId/status'),
      headers: _headers,
      body: jsonEncode({'isActive': isActive}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update status');
  }

  // ==================== AUDIT LOGS ====================

  Future<AuditLogsResponse> getAuditLogs({
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    final uri = Uri.parse('$_baseUrl/admin/audit-logs').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) throw Exception('Failed to load audit logs');
    return AuditLogsResponse.fromJson(jsonDecode(response.body));
  }

  // ==================== SYSTEM HEALTH ====================

  Future<SystemHealth> getSystemHealth() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/health'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Failed to load health status');
    return SystemHealth.fromJson(jsonDecode(response.body));
  }
}

// ==================== MODELS ====================

class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int totalPeople;
  final int totalRelationships;
  final int totalErrors;
  final int unresolvedErrors;
  final double errorRate24h;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int avgPeoplePerUser;

  DashboardStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalPeople,
    required this.totalRelationships,
    required this.totalErrors,
    required this.unresolvedErrors,
    required this.errorRate24h,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.avgPeoplePerUser,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalUsers: json['totalUsers'] ?? 0,
    activeUsers: json['activeUsers'] ?? 0,
    totalPeople: json['totalPeople'] ?? 0,
    totalRelationships: json['totalRelationships'] ?? 0,
    totalErrors: json['totalErrors'] ?? 0,
    unresolvedErrors: json['unresolvedErrors'] ?? 0,
    errorRate24h: (json['errorRate24h'] ?? 0).toDouble(),
    newUsersToday: json['newUsersToday'] ?? 0,
    newUsersThisWeek: json['newUsersThisWeek'] ?? 0,
    avgPeoplePerUser: json['avgPeoplePerUser'] ?? 0,
  );
}

class UserGrowthData {
  final String date;
  final int count;

  UserGrowthData({required this.date, required this.count});

  factory UserGrowthData.fromJson(Map<String, dynamic> json) => UserGrowthData(
    date: json['date'],
    count: json['count'],
  );
}

class TreeSizeDistribution {
  final String sizeRange;
  final int userCount;

  TreeSizeDistribution({required this.sizeRange, required this.userCount});

  factory TreeSizeDistribution.fromJson(Map<String, dynamic> json) => TreeSizeDistribution(
    sizeRange: json['size_range'],
    userCount: json['user_count'],
  );
}

class ActiveUser {
  final String userId;
  final String email;
  final int totalPeople;
  final int totalRelationships;
  final String? lastLoginAt;
  final String createdAt;

  ActiveUser({
    required this.userId,
    required this.email,
    required this.totalPeople,
    required this.totalRelationships,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) => ActiveUser(
    userId: json['user_id'],
    email: json['email'] ?? '',
    totalPeople: json['total_people'] ?? 0,
    totalRelationships: json['total_relationships'] ?? 0,
    lastLoginAt: json['last_login_at'],
    createdAt: json['created_at'],
  );
}

class ErrorLog {
  final String id;
  final DateTime timestamp;
  final String errorType;
  final String severity;
  final int? statusCode;
  final String message;
  final bool resolved;
  final DateTime? resolvedAt;

  ErrorLog({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.severity,
    this.statusCode,
    required this.message,
    required this.resolved,
    this.resolvedAt,
  });

  factory ErrorLog.fromJson(Map<String, dynamic> json) => ErrorLog(
    id: json['id'],
    timestamp: DateTime.parse(json['error_timestamp']),
    errorType: json['error_type'],
    severity: json['severity'],
    statusCode: json['status_code'],
    message: json['message'],
    resolved: json['resolved'] ?? false,
    resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
  );
}

class ErrorLogsResponse {
  final List<ErrorLog> errors;
  final Pagination pagination;

  ErrorLogsResponse({required this.errors, required this.pagination});

  factory ErrorLogsResponse.fromJson(Map<String, dynamic> json) => ErrorLogsResponse(
    errors: (json['errors'] as List).map((e) => ErrorLog.fromJson(e)).toList(),
    pagination: Pagination.fromJson(json['pagination']),
  );
}

class ErrorSummary {
  final String errorType;
  final int count;
  final String severity;
  final String latestOccurrence;

  ErrorSummary({
    required this.errorType,
    required this.count,
    required this.severity,
    required this.latestOccurrence,
  });

  factory ErrorSummary.fromJson(Map<String, dynamic> json) => ErrorSummary(
    errorType: json['error_type'],
    count: json['count'],
    severity: json['severity'],
    latestOccurrence: json['latest_occurrence'],
  );
}

class UserMetadata {
  final String userId;
  final String role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  UserMetadata({
    required this.userId,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory UserMetadata.fromJson(Map<String, dynamic> json) => UserMetadata(
    userId: json['user_id'],
    role: json['role'],
    isActive: json['is_active'] ?? true,
    lastLoginAt: json['last_login_at'] != null ? DateTime.parse(json['last_login_at']) : null,
    createdAt: DateTime.parse(json['created_at']),
  );
}

class UsersResponse {
  final List<UserMetadata> users;
  final Pagination pagination;

  UsersResponse({required this.users, required this.pagination});

  factory UsersResponse.fromJson(Map<String, dynamic> json) => UsersResponse(
    users: (json['users'] as List).map((e) => UserMetadata.fromJson(e)).toList(),
    pagination: Pagination.fromJson(json['pagination']),
  );
}

class AuditLog {
  final String id;
  final String adminUserId;
  final String actionType;
  final String resourceType;
  final String? resourceId;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.adminUserId,
    required this.actionType,
    required this.resourceType,
    this.resourceId,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'],
    adminUserId: json['admin_user_id'],
    actionType: json['action_type'],
    resourceType: json['resource_type'],
    resourceId: json['resource_id'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class AuditLogsResponse {
  final List<AuditLog> logs;
  final Pagination pagination;

  AuditLogsResponse({required this.logs, required this.pagination});

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) => AuditLogsResponse(
    logs: (json['logs'] as List).map((e) => AuditLog.fromJson(e)).toList(),
    pagination: Pagination.fromJson(json['pagination']),
  );
}

class SystemHealth {
  final String status;
  final Map<String, dynamic> database;
  final String timestamp;

  SystemHealth({
    required this.status,
    required this.database,
    required this.timestamp,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) => SystemHealth(
    status: json['status'],
    database: json['database'],
    timestamp: json['timestamp'],
  );
}

class Pagination {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    page: json['page'],
    pageSize: json['pageSize'],
    total: json['total'],
    totalPages: json['totalPages'],
  );
}

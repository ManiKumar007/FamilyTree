import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import 'auth_service.dart';

final statsServiceProvider = Provider<StatsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return StatsService(authService);
});

class StatsService {
  final AuthService _authService;
  static const _timeout = Duration(seconds: 15);
  
  StatsService(this._authService);

  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final token = _authService.accessToken;
    if (token == null) {
      print('⚠️ Warning: No access token available for API call');
    }
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== STATISTICS ====================

  /// Get family statistics
  Future<Map<String, dynamic>> getFamilyStatistics() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stats/family'),
      headers: _headers,
    ).timeout(_timeout);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return wrapper['data'] as Map<String, dynamic>;
  }

  /// Check tree consistency
  Future<List<Map<String, dynamic>>> checkTreeConsistency() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stats/consistency'),
      headers: _headers,
    ).timeout(_timeout);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    // Backend returns { data: { total_issues, issues, issues_by_type } }
    final dataObj = wrapper['data'] as Map<String, dynamic>;
    final List<dynamic> issues = dataObj['issues'] as List<dynamic>;
    return issues.map((item) => item as Map<String, dynamic>).toList();
  }

  /// Find relationship path between two persons
  Future<List<String>> findRelationshipPath(String personId1, String personId2, {int maxDepth = 10}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/stats/relationship-path'),
      headers: _headers,
      body: jsonEncode({
        'person_id_1': personId1,
        'person_id_2': personId2,
        'max_depth': maxDepth,
      }),
    ).timeout(_timeout);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    final List<dynamic> data = wrapper['data'] as List<dynamic>;
    return data.map((id) => id as String).toList();
  }

  /// Get tree depth (generations)
  Future<int> getTreeDepth() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stats/tree-depth'),
      headers: _headers,
    ).timeout(_timeout);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return wrapper['data']['depth'] as int;
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleError(http.Response response) {
    print('❌ API Error: ${response.statusCode} - ${response.body}');
    
    try {
      final error = jsonDecode(response.body);
      final message = error['error'] ?? error['message'] ?? 'Unknown error';
      return Exception(message);
    } catch (e) {
      return Exception('Request failed with status ${response.statusCode}');
    }
  }
}

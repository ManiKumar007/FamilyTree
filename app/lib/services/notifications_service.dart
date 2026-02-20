import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'auth_service.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return NotificationsService(authService);
});

class NotificationsService {
  final AuthService _authService;
  
  NotificationsService(this._authService);

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

  // ==================== NOTIFICATIONS ====================

  /// Get user's notifications (paginated)
  Future<List<Notification>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool? unreadOnly,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (unreadOnly != null) 'unread_only': unreadOnly.toString(),
    };
    
    final uri = Uri.parse('$_baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    final List<dynamic> data = wrapper['data'] as List<dynamic>;
    return data.map((json) => Notification.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/notifications/unread-count'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return wrapper['data']['count'] as int;
  }

  /// Mark a notification as read
  Future<Notification> markAsRead(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return Notification.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final response = await http.put(
      Uri.parse('$_baseUrl/notifications/mark-all-read'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/notifications/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
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

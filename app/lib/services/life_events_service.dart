import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'auth_service.dart';

final lifeEventsServiceProvider = Provider<LifeEventsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LifeEventsService(authService);
});

class LifeEventsService {
  final AuthService _authService;
  
  LifeEventsService(this._authService);

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

  // ==================== LIFE EVENTS ====================

  /// Get life events for a person
  Future<List<LifeEvent>> getLifeEventsByPerson(String personId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/life-events/person/$personId'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    final List<dynamic> data = wrapper['data'] as List<dynamic>;
    return data.map((json) => LifeEvent.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Create a new life event
  Future<LifeEvent> createLifeEvent(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/life-events'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 201) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return LifeEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Get a single life event by ID
  Future<LifeEvent> getLifeEvent(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/life-events/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return LifeEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Update a life event
  Future<LifeEvent> updateLifeEvent(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/life-events/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return LifeEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Delete a life event
  Future<void> deleteLifeEvent(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/life-events/$id'),
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

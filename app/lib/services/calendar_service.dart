import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'auth_service.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CalendarService(authService);
});

class CalendarService {
  final AuthService _authService;
  
  CalendarService(this._authService);

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

  // ==================== CALENDAR EVENTS ====================

  /// Get all calendar events
  Future<List<FamilyEvent>> getEvents({
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (eventType != null) queryParams['event_type'] = eventType;
    
    final uri = Uri.parse('$_baseUrl/calendar/events').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    final List<dynamic> data = wrapper['data'] as List<dynamic>;
    return data.map((json) => FamilyEvent.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get upcoming events
  Future<List<FamilyEvent>> getUpcomingEvents({int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl/calendar/upcoming').replace(queryParameters: {'limit': limit.toString()});
    final response = await http.get(uri, headers: _headers);
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    final List<dynamic> data = wrapper['data'] as List<dynamic>;
    return data.map((json) => FamilyEvent.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Create a new calendar event
  Future<FamilyEvent> createEvent(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/calendar/events'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 201) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return FamilyEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Get a single event by ID
  Future<FamilyEvent> getEvent(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/calendar/events/$id'),
      headers: _headers,
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return FamilyEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Update an event
  Future<FamilyEvent> updateEvent(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/calendar/events/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    if (response.statusCode != 200) throw _handleError(response);
    
    final wrapper = jsonDecode(response.body);
    return FamilyEvent.fromJson(wrapper['data'] as Map<String, dynamic>);
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/calendar/events/$id'),
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

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import '../models/models.dart';
import 'auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  final AuthService _authService;
  static const _timeout = Duration(seconds: 15);
  
  ApiService(this._authService);

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

  // ==================== GENERIC HTTP METHODS ====================

  /// Generic GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) throw _handleError(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(data),
    ).timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _handleError(response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== PERSONS ====================

  /// Get current user's profile
  Future<Person?> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/persons/me/profile'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return Person.fromJson(wrapper['data']);
  }

  /// Create a new person
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> data) async {
    print('\n📡 API Service - Creating person');
    print('URL: $_baseUrl/persons');
    print('Has Token: ${_authService.accessToken != null}');
    if (_authService.accessToken != null) {
      print('Token Length: ${_authService.accessToken!.length}');
      print('Token Preview: ${_authService.accessToken!.substring(0, min(30, _authService.accessToken!.length))}...');
    }
    print('Data keys: ${data.keys.join(", ")}');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/persons'),
      headers: _headers,
      body: jsonEncode(data),
    );
    
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode != 201) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return wrapper['data'] as Map<String, dynamic>;
  }

  /// Get person by ID
  Future<Person> getPerson(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/persons/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return Person.fromJson(wrapper['data']);
  }

  /// Update person
  Future<Person> updatePerson(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/persons/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return Person.fromJson(wrapper['data']);
  }

  // ==================== IMAGE UPLOAD ====================

  /// Upload profile image to Supabase Storage
  Future<String> uploadProfileImage(String personId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Determine file extension and content type safely.
      // On web, imageFile.path is a blob URL (e.g. blob:http://...),
      // so we use mimeType or the original file name instead.
      String contentType = 'image/jpeg'; // safe default
      String fileExt = 'jpg';

      final mime = imageFile.mimeType;
      if (mime != null && mime.startsWith('image/')) {
        contentType = mime;
        // e.g. 'image/png' -> 'png', 'image/jpeg' -> 'jpeg'
        fileExt = mime.split('/').last;
        if (fileExt == 'jpeg') fileExt = 'jpg';
      } else {
        // Try to extract from the original file name (works on mobile & some web pickers)
        final name = imageFile.name;
        if (name.contains('.')) {
          final ext = name.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
            fileExt = ext;
            contentType = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
          }
        }
      }

      final fileName = '$personId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profiles/$fileName';

      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete profile image from Supabase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePathIndex = pathSegments.indexOf('avatars') + 1;
      if (filePathIndex >= pathSegments.length) return;
      
      final filePath = pathSegments.sublist(filePathIndex).join('/');

      // Delete from Supabase Storage
      final supabase = Supabase.instance.client;
      await supabase.storage.from('avatars').remove([filePath]);
    } catch (e) {
      // Silently fail - don't throw error if deletion fails
      print('Warning: Could not delete image: $e');
    }
  }

  // ==================== TREE ====================

  /// Get user's full family tree
  Future<TreeResponse> getMyTree() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tree'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return TreeResponse.fromJson(wrapper['data']);
  }

  /// Get tree centered on a specific person
  Future<TreeResponse> getTree(String personId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tree/$personId'),
      headers: _headers,
    ).timeout(_timeout);
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return TreeResponse.fromJson(wrapper['data']);
  }

  // ==================== RELATIONSHIPS ====================

  /// Create a relationship
  Future<Relationship> createRelationship({
    required String personId,
    required String relatedPersonId,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/relationships'),
      headers: _headers,
      body: jsonEncode({
        'person_id': personId,
        'related_person_id': relatedPersonId,
        'type': type,
      }),
    );
    if (response.statusCode != 201) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return Relationship.fromJson(wrapper['data']);
  }

  /// Get relationships for a person
  Future<List<Relationship>> getRelationships(String personId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/relationships/$personId'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    final list = wrapper['data'] as List;
    return list.map((r) => Relationship.fromJson(r)).toList();
  }

  // ==================== SEARCH ====================

  /// Search within N circles
  Future<List<SearchResult>> search({
    String? query,
    String? occupation,
    String? city,
    String? state,
    String? maritalStatus,
    int depth = 3,
  }) async {
    final params = <String, String>{
      'depth': depth.toString(),
      if (query != null) 'query': query,
      if (occupation != null) 'occupation': occupation,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (maritalStatus != null) 'marital_status': maritalStatus,
    };

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) throw _handleError(response);

    final body = jsonDecode(response.body);
    final results = body['data'] as List;
    return results.map((r) => SearchResult.fromJson(r)).toList();
  }

  // ==================== MERGE ====================

  /// Get pending merge requests
  Future<List<MergeRequest>> getPendingMergeRequests() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/merge/pending'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    final list = wrapper['data'] as List;
    return list.map((r) => MergeRequest.fromJson(r)).toList();
  }

  /// Approve merge request
  Future<void> approveMerge(String id, {Map<String, dynamic>? resolvedFields}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/merge/$id/approve'),
      headers: _headers,
      body: jsonEncode({'resolved_fields': resolvedFields}),
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  /// Reject merge request
  Future<void> rejectMerge(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/merge/$id/reject'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
  }

  // ==================== INVITE ====================

  /// Generate invite link
  Future<Map<String, dynamic>> generateInvite(String personId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite/generate'),
      headers: _headers,
      body: jsonEncode({'person_id': personId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _handleError(response);
    }
    final wrapper = jsonDecode(response.body);
    return wrapper['data'] as Map<String, dynamic>;
  }

  /// Claim invite
  Future<Map<String, dynamic>> claimInvite(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite/claim'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return wrapper['data'] as Map<String, dynamic>;
  }

  // ==================== CONNECTION FINDER ====================

  /// Find the connection path between two persons by their IDs
  Future<ConnectionResult> findConnection(String personAId, String personBId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tree/connection/$personAId/$personBId'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return ConnectionResult.fromJson(wrapper['data']);
  }

  /// Find the connection path between two persons by their usernames
  Future<ConnectionResult> findConnectionByUsername(String usernameA, String usernameB) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tree/connection-by-username/$usernameA/$usernameB'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return ConnectionResult.fromJson(wrapper['data']);
  }

  /// Check if a username is available
  Future<bool> checkUsernameAvailability(String username) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/persons/check-username/$username'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final wrapper = jsonDecode(response.body);
    return wrapper['data']['available'] as bool;
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final error = body['error'];
      if (error is Map) {
        return Exception(error['message'] ?? 'Unknown error (${response.statusCode})');
      }
      return Exception(error?.toString() ?? 'Unknown error (${response.statusCode})');
    } catch (_) {
      return Exception('Request failed with status ${response.statusCode}');
    }
  }
}

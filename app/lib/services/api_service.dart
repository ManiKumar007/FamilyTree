import 'dart:convert';
import 'dart:io';
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
  
  ApiService(this._authService);

  String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null)
      'Authorization': 'Bearer ${_authService.accessToken}',
  };

  // ==================== PERSONS ====================

  /// Get current user's profile
  Future<Person?> getMyProfile() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/persons/me/profile'),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw _handleError(response);
    return Person.fromJson(jsonDecode(response.body));
  }

  /// Create a new person
  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/persons'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) throw _handleError(response);
    return jsonDecode(response.body);
  }

  /// Get person by ID
  Future<Person> getPerson(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/persons/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    return Person.fromJson(jsonDecode(response.body));
  }

  /// Update person
  Future<Person> updatePerson(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/persons/$id'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw _handleError(response);
    return Person.fromJson(jsonDecode(response.body));
  }

  // ==================== IMAGE UPLOAD ====================

  /// Upload profile image to Supabase Storage
  Future<String> uploadProfileImage(String personId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$personId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profiles/$fileName';

      // Upload to Supabase Storage
      final supabase = Supabase.instance.client;
      await supabase.storage.from('avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/${fileExt == 'jpg' ? 'jpeg' : fileExt}',
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
    );
    if (response.statusCode != 200) throw _handleError(response);
    return TreeResponse.fromJson(jsonDecode(response.body));
  }

  /// Get tree centered on a specific person
  Future<TreeResponse> getTree(String personId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tree/$personId'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    return TreeResponse.fromJson(jsonDecode(response.body));
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
    return Relationship.fromJson(jsonDecode(response.body));
  }

  /// Get relationships for a person
  Future<List<Relationship>> getRelationships(String personId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/relationships/$personId'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw _handleError(response);
    final list = jsonDecode(response.body) as List;
    return list.map((r) => Relationship.fromJson(r)).toList();
  }

  // ==================== SEARCH ====================

  /// Search within N circles
  Future<List<SearchResult>> search({
    String? query,
    String? occupation,
    String? maritalStatus,
    int depth = 3,
  }) async {
    final params = <String, String>{
      'depth': depth.toString(),
      if (query != null) 'query': query,
      if (occupation != null) 'occupation': occupation,
      if (maritalStatus != null) 'marital_status': maritalStatus,
    };

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) throw _handleError(response);

    final body = jsonDecode(response.body);
    final results = body['results'] as List;
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
    final list = jsonDecode(response.body) as List;
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
    return jsonDecode(response.body);
  }

  /// Claim invite
  Future<Map<String, dynamic>> claimInvite(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/invite/claim'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode != 200) throw _handleError(response);
    return jsonDecode(response.body);
  }

  // ==================== ERROR HANDLING ====================

  Exception _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return Exception(body['error'] ?? 'Unknown error (${response.statusCode})');
    } catch (_) {
      return Exception('Request failed with status ${response.statusCode}');
    }
  }
}

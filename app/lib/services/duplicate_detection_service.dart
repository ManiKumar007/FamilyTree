import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Represents a potential duplicate person
class DuplicateMatch {
  final String personId;
  final String name;
  final String? phone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? city;
  final double matchScore; // 0.0 to 1.0
  final List<String> matchReasons;

  DuplicateMatch({
    required this.personId,
    required this.name,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.city,
    required this.matchScore,
    required this.matchReasons,
  });

  factory DuplicateMatch.fromJson(Map<String, dynamic> json) {
    return DuplicateMatch(
      personId: json['person_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      city: json['city'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
      matchReasons: List<String>.from(json['match_reasons'] ?? []),
    );
  }
}

/// Service for detecting duplicate persons
class DuplicateDetectionService {
  final ApiService _apiService;

  DuplicateDetectionService(this._apiService);

  /// Check for potential duplicates before adding a person
  Future<List<DuplicateMatch>> checkForDuplicates({
    required String name,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
    String? city,
  }) async {
    final queryParams = <String, String>{
      'name': name,
    };

    if (phone != null && phone.isNotEmpty) {
      queryParams['phone'] = phone;
    }
    if (email != null && email.isNotEmpty) {
      queryParams['email'] = email;
    }
    if (dateOfBirth != null) {
      queryParams['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _apiService.get('/api/persons/check-duplicates?$queryString');
    
    final matches = List<Map<String, dynamic>>.from(response['matches'] ?? []);
    return matches.map((m) => DuplicateMatch.fromJson(m)).toList();
  }

  /// Find all potential duplicates in the entire tree
  Future<List<Map<String, dynamic>>> findAllDuplicates() async {
    final response = await _apiService.get('/api/persons/find-duplicates');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Merge two person records
  Future<Map<String, dynamic>> mergePersons({
    required String keepPersonId,
    required String mergePersonId,
    Map<String, dynamic>? fieldOverrides,
  }) async {
    final response = await _apiService.post('/api/persons/merge', {
      'keep_person_id': keepPersonId,
      'merge_person_id': mergePersonId,
      'field_overrides': fieldOverrides ?? {},
    });
    return response;
  }

  /// Calculate similarity score between two names
  double calculateNameSimilarity(String name1, String name2) {
    final n1 = name1.toLowerCase().trim();
    final n2 = name2.toLowerCase().trim();

    if (n1 == n2) return 1.0;

    // Simple Levenshtein-inspired similarity
    final longer = n1.length > n2.length ? n1 : n2;
    final shorter = n1.length > n2.length ? n2 : n1;

    if (longer.isEmpty) return 0.0;

    final maxDistance = longer.length;
    final distance = _levenshteinDistance(n1, n2);

    return 1.0 - (distance / maxDistance);
  }

  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }
}

/// Provider for DuplicateDetectionService
final duplicateDetectionServiceProvider = Provider<DuplicateDetectionService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DuplicateDetectionService(apiService);
});

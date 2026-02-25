import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Service for fetching family timeline data
class TimelineService {
  final ApiService _apiService;

  TimelineService(this._apiService);

  /// Get chronological timeline of family events
  Future<List<Map<String, dynamic>>> getFamilyTimeline() async {
    final response = await _apiService.get('/api/timeline');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Get timeline grouped by generations
  Future<Map<String, dynamic>> getGenerationalTimeline() async {
    final response = await _apiService.get('/api/timeline/generations');
    return response;
  }

  /// Get family growth statistics over time
  Future<Map<String, dynamic>> getGrowthStatistics() async {
    final response = await _apiService.get('/api/timeline/growth');
    return response;
  }
}

/// Provider for TimelineService
final timelineServiceProvider = Provider<TimelineService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TimelineService(apiService);
});

/// Provider for family timeline
final familyTimelineProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(timelineServiceProvider);
  return service.getFamilyTimeline();
});

/// Provider for generational timeline
final generationalTimelineProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(timelineServiceProvider);
  return service.getGenerationalTimeline();
});

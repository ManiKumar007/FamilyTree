import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Service for managing event reminders (birthdays, anniversaries, etc.)
class RemindersService {
  final ApiService _apiService;

  RemindersService(this._apiService);

  /// Get upcoming events/reminders for the user
  Future<Map<String, dynamic>> getUpcomingReminders({int daysAhead = 30}) async {
    final response = await _apiService.get('/api/reminders/upcoming?days=$daysAhead');
    return response;
  }

  /// Get all family events
  Future<List<Map<String, dynamic>>> getFamilyEvents() async {
    final response = await _apiService.get('/api/family-events');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Create a new family event reminder
  Future<Map<String, dynamic>> createFamilyEvent({
    required String title,
    required String eventType,
    required DateTime eventDate,
    String? description,
    String? personId,
    bool isRecurring = false,
    String recurrenceType = 'none',
    int reminderDaysBefore = 1,
  }) async {
    final response = await _apiService.post('/api/family-events', {
      'title': title,
      'event_type': eventType,
      'event_date': eventDate.toIso8601String(),
      'description': description,
      'person_id': personId,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
      'reminder_days_before': reminderDaysBefore,
    });
    return response;
  }

  /// Update a family event
  Future<Map<String, dynamic>> updateFamilyEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiService.put('/api/family-events/$eventId', updates);
    return response;
  }

  /// Delete a family event
  Future<void> deleteFamilyEvent(String eventId) async {
    await _apiService.delete('/api/family-events/$eventId');
  }

  /// Get birthday reminders
  Future<List<Map<String, dynamic>>> getBirthdayReminders() async {
    final response = await _apiService.get('/api/reminders/birthdays');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Get anniversary reminders
  Future<List<Map<String, dynamic>>> getAnniversaryReminders() async {
    final response = await _apiService.get('/api/reminders/anniversaries');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _apiService.put('/api/notifications/$notificationId/read', {});
  }
}

/// Provider for RemindersService
final remindersServiceProvider = Provider<RemindersService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RemindersService(apiService);
});

/// Provider for upcoming reminders
final upcomingRemindersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(remindersServiceProvider);
  return service.getUpcomingReminders();
});

/// Provider for family events
final familyEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(remindersServiceProvider);
  return service.getFamilyEvents();
});

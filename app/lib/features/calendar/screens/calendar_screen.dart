import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/calendar_service.dart';
import '../../../models/models.dart';
import '../../../config/theme.dart';
import '../../../widgets/common_widgets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  List<FamilyEvent>? _events;
  List<FamilyEvent>? _upcomingEvents;
  bool _isLoading = true;
  String? _loadError;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final service = ref.read(calendarServiceProvider);
      
      // Get all events for the month
      final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
      
      final events = await service.getEvents(
        startDate: firstDay.toIso8601String().split('T')[0],
        endDate: lastDay.toIso8601String().split('T')[0],
      );
      
      final upcoming = await service.getUpcomingEvents(limit: 5);
      
      setState(() { 
        _events = events;
        _upcomingEvents = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { 
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final service = ref.read(calendarServiceProvider);
      await service.deleteEvent(id);
      _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Calendar',
                  subtitle: _loadError!,
                  actionLabel: 'Retry',
                  onAction: _loadEvents,
                )
              : RefreshIndicator(
                  onRefresh: _loadEvents,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month Selector
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: _buildMonthSelector(),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Calendar Grid
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: _buildCalendarGrid(),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Upcoming Events
                        const SectionHeader(
                          title: 'Upcoming Events',
                          icon: Icons.event,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildUpcomingEvents(),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Events for selected date
                        if (_getEventsForDate(_selectedDate).isNotEmpty) ...[
                          SectionHeader(
                            title: 'Events on ${_formatDate(_selectedDate)}',
                            icon: Icons.event_note,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildEventsForDate(),
                        ],
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add event screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add event feature coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            });
            _loadEvents();
          },
        ),
        Text(
          _formatMonth(_focusedMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            });
            _loadEvents();
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startingWeekday = firstDay.weekday % 7; // 0 = Sunday
    
    final List<Widget> dayHeaders = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        .map((day) => Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
            ))
        .toList();
    
    final List<Widget> dayWidgets = [];
    
    // Empty cells before first day
    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }
    
    // Day cells
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final hasEvents = _getEventsForDate(date).isNotEmpty;
      final isSelected = _isSameDay(date, _selectedDate);
      final isToday = _isSameDay(date, DateTime.now());
      
      dayWidgets.add(
        InkWell(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? kPrimaryColor : null,
              border: isToday ? Border.all(color: kPrimaryColor, width: 2) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : kTextPrimary,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasEvents)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : kAccentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: dayHeaders,
        ),
        const Divider(),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: dayWidgets,
        ),
      ],
    );
  }

  Widget _buildUpcomingEvents() {
    if (_upcomingEvents == null || _upcomingEvents!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No upcoming events')),
        ),
      );
    }
    
    return Column(
      children: _upcomingEvents!.map((event) => _buildEventCard(event)).toList(),
    );
  }

  Widget _buildEventsForDate() {
    final events = _getEventsForDate(_selectedDate);
    return Column(
      children: events.map((event) => _buildEventCard(event)).toList(),
    );
  }

  Widget _buildEventCard(FamilyEvent event) {
    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: kErrorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteEvent(event.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _getEventColor(event.eventType).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getEventIcon(event.eventType),
              color: _getEventColor(event.eventType),
            ),
          ),
          title: Text(event.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.description != null && event.description!.isNotEmpty)
                Text(event.description!),
              const SizedBox(height: 4),
              Text(
                _formatEventDate(event),
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
              if (event.location != null && event.location!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      event.location!,
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
            ],
          ),
          trailing: event.relatedPersonId != null
              ? IconButton(
                  icon: const Icon(Icons.person, size: 20),
                  onPressed: () {
                    // Navigate to person detail
                  },
                  tooltip: 'View person',
                )
              : null,
        ),
      ),
    );
  }

  List<FamilyEvent> _getEventsForDate(DateTime date) {
    if (_events == null) return [];
    return _events!.where((event) {
      try {
        final eventDate = DateTime.parse(event.eventDate);
        return _isSameDay(eventDate, date);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonth(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatEventDate(FamilyEvent event) {
    try {
      final date = DateTime.parse(event.eventDate);
      if (event.allDay) {
        return _formatDate(date);
      } else {
        return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return event.eventDate;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.celebration;
      case 'wedding':
        return Icons.favorite;
      case 'death_anniversary':
        return Icons.front_hand;
      case 'reunion':
        return Icons.groups;
      case 'holiday':
        return Icons.celebration_outlined;
      case 'other':
        return Icons.event;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'birthday':
        return kAccentColor;
      case 'anniversary':
      case 'wedding':
        return kRelationshipSpouse;
      case 'death_anniversary':
        return Colors.grey;
      case 'reunion':
        return kSuccessColor;
      case 'holiday':
        return kPrimaryColor;
      default:
        return kSecondaryColor;
    }
  }
}

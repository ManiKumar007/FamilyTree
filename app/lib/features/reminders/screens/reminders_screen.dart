import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/reminders_service.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Reminders'),
        backgroundColor: kPrimaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming', icon: Icon(Icons.event, size: 20)),
            Tab(text: 'Birthdays', icon: Icon(Icons.cake, size: 20)),
            Tab(text: 'Anniversaries', icon: Icon(Icons.favorite, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildBirthdaysTab(),
          _buildAnniversariesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingAsync = ref.watch(upcomingRemindersProvider);

    return upcomingAsync.when(
      data: (data) {
        final events = List<Map<String, dynamic>>.from(data['events'] ?? []);
        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            message: 'No upcoming events in the next 30 days',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading reminders: $error'),
      ),
    );
  }

  Widget _buildBirthdaysTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(remindersServiceProvider).getBirthdayReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final birthdays = snapshot.data ?? [];
        if (birthdays.isEmpty) {
          return _buildEmptyState(
            icon: Icons.cake,
            message: 'No upcoming birthdays',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: birthdays.length,
          itemBuilder: (context, index) {
            final birthday = birthdays[index];
            return _buildBirthdayCard(birthday);
          },
        );
      },
    );
  }

  Widget _buildAnniversariesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(remindersServiceProvider).getAnniversaryReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final anniversaries = snapshot.data ?? [];
        if (anniversaries.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite,
            message: 'No upcoming anniversaries',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: anniversaries.length,
          itemBuilder: (context, index) {
            final anniversary = anniversaries[index];
            return _buildAnniversaryCard(anniversary);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title'] as String? ?? 'Untitled Event';
    final eventDate = DateTime.tryParse(event['event_date'] as String? ?? '');
    final eventType = event['event_type'] as String? ?? 'custom';
    final daysUntil = eventDate != null
        ? eventDate.difference(DateTime.now()).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventColor(eventType),
          child: Icon(_getEventIcon(eventType), color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eventDate != null)
              Text(DateFormat('MMM dd, yyyy').format(eventDate)),
            if (daysUntil >= 0)
              Text(
                daysUntil == 0
                    ? 'Today!'
                    : daysUntil == 1
                        ? 'Tomorrow'
                        : 'In $daysUntil days',
                style: TextStyle(
                  color: daysUntil <= 3 ? kAccentColor : kTextSecondary,
                  fontWeight: daysUntil <= 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.notifications_active),
          onPressed: () {
            // Set reminder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder set!')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBirthdayCard(Map<String, dynamic> birthday) {
    final name = birthday['name'] as String? ?? 'Unknown';
    final dateOfBirth = DateTime.tryParse(birthday['date_of_birth'] as String? ?? '');
    final nextBirthday = _getNextBirthday(dateOfBirth);
    final age = dateOfBirth != null
        ? DateTime.now().year - dateOfBirth.year
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: kAccentColor,
          child: Icon(Icons.cake, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nextBirthday != null)
              Text(DateFormat('MMM dd').format(nextBirthday)),
            if (age != null) Text('Turning ${age + 1}'),
          ],
        ),
        trailing: Text(
          _getDaysUntilText(nextBirthday),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnniversaryCard(Map<String, dynamic> anniversary) {
    final couple = anniversary['couple'] as String? ?? 'Unknown';
    final weddingDate = DateTime.tryParse(anniversary['wedding_date'] as String? ?? '');
    final nextAnniversary = _getNextBirthday(weddingDate);
    final years = weddingDate != null
        ? DateTime.now().year - weddingDate.year
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.pink,
          child: Icon(Icons.favorite, color: Colors.white),
        ),
        title: Text(
          couple,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nextAnniversary != null)
              Text(DateFormat('MMM dd').format(nextAnniversary)),
            if (years != null) Text('${years + 1} years'),
          ],
        ),
        trailing: Text(
          _getDaysUntilText(nextAnniversary),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: kTextSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: const TextStyle(color: kTextSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  DateTime? _getNextBirthday(DateTime? birthDate) {
    if (birthDate == null) return null;

    final now = DateTime.now();
    var next = DateTime(now.year, birthDate.month, birthDate.day);

    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }

    return next;
  }

  String _getDaysUntilText(DateTime? date) {
    if (date == null) return '';
    
    final daysUntil = date.difference(DateTime.now()).inDays;
    if (daysUntil == 0) return 'Today!';
    if (daysUntil == 1) return 'Tomorrow';
    return '$daysUntil days';
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'birthday':
        return kAccentColor;
      case 'wedding_anniversary':
      case 'anniversary':
        return Colors.pink;
      case 'death_anniversary':
        return Colors.grey;
      case 'festival':
        return Colors.orange;
      default:
        return kPrimaryColor;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birthday':
        return Icons.cake;
      case 'wedding_anniversary':
      case 'anniversary':
        return Icons.favorite;
      case 'death_anniversary':
        return Icons.local_florist;
      case 'festival':
        return Icons.celebration;
      default:
        return Icons.event;
    }
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String eventType = 'custom';
    bool isRecurring = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: eventType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                    DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
                    DropdownMenuItem(value: 'festival', child: Text('Festival')),
                  ],
                  onChanged: (value) {
                    setState(() => eventType = value ?? 'custom');
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                CheckboxListTile(
                  title: const Text('Recurring (Yearly)'),
                  value: isRecurring,
                  onChanged: (value) {
                    setState(() => isRecurring = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter event title')),
                  );
                  return;
                }

                try {
                  await ref.read(remindersServiceProvider).createFamilyEvent(
                        title: titleController.text,
                        eventType: eventType,
                        eventDate: selectedDate,
                        description: descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text,
                        isRecurring: isRecurring,
                        recurrenceType: isRecurring ? 'yearly' : 'none',
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event reminder created!')),
                    );
                    ref.invalidate(upcomingRemindersProvider);
                    ref.invalidate(familyEventsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

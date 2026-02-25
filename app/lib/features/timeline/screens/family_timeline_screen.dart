import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../services/timeline_service.dart';
import '../../../config/theme.dart';

class FamilyTimelineScreen extends ConsumerStatefulWidget {
  const FamilyTimelineScreen({super.key});

  @override
  ConsumerState<FamilyTimelineScreen> createState() => _FamilyTimelineScreenState();
}

class _FamilyTimelineScreenState extends ConsumerState<FamilyTimelineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _visibleEventsCount = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playTimeline(int totalEvents) {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      _visibleEventsCount = 0;
    });

    // Animate through events
    for (int i = 0; i < totalEvents; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (mounted) {
          setState(() => _visibleEventsCount = i + 1);
        }
      });
    }

    // Reset play button after animation
    Future.delayed(Duration(milliseconds: totalEvents * 500 + 500), () {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(familyTimelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Timeline'),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              timelineAsync.whenData((events) {
                if (_isPlaying) {
                  setState(() {
                    _isPlaying = false;
                    _visibleEventsCount = events.length;
                  });
                } else {
                  _playTimeline(events.length);
                }
              });
            },
            tooltip: 'Play Timeline Animation',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTimeline(),
            tooltip: 'Share Timeline',
          ),
        ],
      ),
      body: timelineAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return _buildEmptyState();
          }

          // Show all events initially or during animation
          final visibleEvents = _visibleEventsCount == 0
              ? events
              : events.take(_visibleEventsCount).toList();

          return Column(
            children: [
              // Timeline header with stats
              _buildTimelineHeader(events),
              // Scrollable timeline
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: visibleEvents.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineEvent(
                      visibleEvents[index],
                      index,
                      index == visibleEvents.length - 1,
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: kErrorColor),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading timeline: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineHeader(List<Map<String, dynamic>> events) {
    final totalMembers = events.where((e) => e['event_type'] == 'birth' || e['event_type'] == 'person_added').length;
    final marriages = events.where((e) => e['event_type'] == 'marriage').length;
    final generations = _calculateGenerations(events);
    
    final oldestDate = events.isNotEmpty
        ? DateTime.tryParse(events.first['event_date'] as String? ?? '')
        : null;
    final newestDate = events.isNotEmpty
        ? DateTime.tryParse(events.last['event_date'] as String? ?? '')
        : null;
    
    final yearsSpan = oldestDate != null && newestDate != null
        ? newestDate.year - oldestDate.year
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Members', '$totalMembers', Icons.people),
              _buildStatCard('Marriages', '$marriages', Icons.favorite),
              _buildStatCard('Generations', '$generations', Icons.family_restroom),
              _buildStatCard('Years', '$yearsSpan+', Icons.calendar_today),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Watch your family tree grow through time! 🌳',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEvent(
    Map<String, dynamic> event,
    int index,
    bool isLast,
  ) {
    final eventType = event['event_type'] as String? ?? 'unknown';
    final title = event['title'] as String? ?? 'Unknown Event';
    final date = DateTime.tryParse(event['event_date'] as String? ?? '');
    final personName = event['person_name'] as String?;
    final description = event['description'] as String?;

    final eventColor = _getEventColor(eventType);
    final eventIcon = _getEventIcon(eventType);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: eventColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: eventColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(eventIcon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: eventColor.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // Event card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (date != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: eventColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat('MMM yyyy').format(date),
                              style: TextStyle(
                                color: eventColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (personName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        personName,
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildEventBadge(eventType),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBadge(String eventType) {
    String label;
    switch (eventType) {
      case 'birth':
        label = '👶 Birth';
        break;
      case 'marriage':
        label = '💒 Marriage';
        break;
      case 'death':
        label = '🕊️ In Memory';
        break;
      case 'person_added':
        label = '➕ Added to Tree';
        break;
      default:
        label = '📌 Event';
    }

    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: kTextSecondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: kTextSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No timeline events yet',
            style: const TextStyle(fontSize: 16, color: kTextSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add family members to see the timeline',
            style: const TextStyle(fontSize: 14, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'birth':
      case 'person_added':
        return Colors.green;
      case 'marriage':
        return Colors.pink;
      case 'death':
        return Colors.grey;
      default:
        return kPrimaryColor;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'birth':
        return Icons.child_care;
      case 'person_added':
        return Icons.person_add;
      case 'marriage':
        return Icons.favorite;
      case 'death':
        return Icons.local_florist;
      default:
        return Icons.event;
    }
  }

  int _calculateGenerations(List<Map<String, dynamic>> events) {
    // Simple heuristic: count unique generation levels if available
    // Otherwise estimate based on date ranges
    final uniqueGenerations = <int>{};
    for (final event in events) {
      final generation = event['generation'] as int?;
      if (generation != null) {
        uniqueGenerations.add(generation);
      }
    }
    
    if (uniqueGenerations.isNotEmpty) {
      return uniqueGenerations.length;
    }
    
    // Fallback: estimate based on 25-year generations
    final dates = events
        .map((e) => DateTime.tryParse(e['event_date'] as String? ?? ''))
        .where((d) => d != null)
        .cast<DateTime>()
        .toList();
    
    if (dates.isEmpty) return 1;
    
    dates.sort();
    final yearSpan = dates.last.year - dates.first.year;
    return (yearSpan / 25).ceil() + 1;
  }

  void _shareTimeline() {
    // TODO: Implement sharing functionality
    // This would generate an image/video of the timeline and share it
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Text('Share your family timeline with loved ones! 📱'),
          ],
        ),
        backgroundColor: kPrimaryColor,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

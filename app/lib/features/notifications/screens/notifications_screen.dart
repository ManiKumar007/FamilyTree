import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/notifications_service.dart';
import '../../../models/models.dart' as models;
import '../../../config/theme.dart';
import '../../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<models.Notification>? _notifications;
  bool _isLoading = true;
  String? _loadError;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final service = ref.read(notificationsServiceProvider);
      final notifications = await service.getNotifications(
        unreadOnly: _showUnreadOnly ? true : null,
      );
      setState(() { 
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { 
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      final service = ref.read(notificationsServiceProvider);
      await service.markAsRead(id);
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as read: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final service = ref.read(notificationsServiceProvider);
      await service.markAllAsRead();
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark all as read: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final service = ref.read(notificationsServiceProvider);
      await service.deleteNotification(id);
      _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Error Loading Notifications',
          subtitle: _loadError!,
          actions: [
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications != null && _notifications!.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
            ),
          IconButton(
            icon: Icon(_showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() { _showUnreadOnly = !_showUnreadOnly; });
              _loadNotifications();
            },
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
          ),
        ],
      ),
      body: _notifications == null || _notifications!.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none,
              title: _showUnreadOnly ? 'No Unread Notifications' : 'No Notifications',
              subtitle: _showUnreadOnly 
                  ? 'All caught up! No unread notifications.'
                  : 'You have no notifications yet',
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _notifications!.length,
                itemBuilder: (context, index) {
                  final notification = _notifications![index];
                  return _buildNotificationCard(notification);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(models.Notification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: kErrorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id),
      child: Card(
        color: notification.isRead ? null : kPrimaryColor.withOpacity(0.05),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.notificationType).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.notificationType),
              color: _getNotificationColor(notification.notificationType),
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xs),
              Text(notification.message),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatTimestamp(notification.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? IconButton(
                  icon: const Icon(Icons.mark_email_read_outlined, size: 20),
                  onPressed: () => _markAsRead(notification.id),
                  tooltip: 'Mark as read',
                )
              : null,
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            // Navigate to related item if applicable
            if (notification.relatedPersonId != null) {
              context.push('/person/${notification.relatedPersonId}');
            } else if (notification.relatedPostId != null) {
              // Navigate to forum post when implemented
            }
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.celebration;
      case 'forum_comment':
        return Icons.comment;
      case 'forum_like':
        return Icons.favorite;
      case 'new_member':
        return Icons.person_add;
      case 'relationship_added':
        return Icons.people;
      case 'profile_updated':
        return Icons.edit;
      case 'merge_request':
        return Icons.merge;
      case 'system':
        return Icons.info;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
      case 'anniversary':
        return kAccentColor;
      case 'forum_comment':
      case 'forum_like':
        return kPrimaryColor;
      case 'new_member':
      case 'relationship_added':
        return kSuccessColor;
      case 'merge_request':
        return kWarningColor;
      case 'system':
        return kInfoColor;
      default:
        return kSecondaryColor;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return timestamp;
    }
  }
}

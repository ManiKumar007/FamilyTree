import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_providers.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usersProvider);
    final notifier = ref.read(usersProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Role',
            onSelected: (value) {
              notifier.setRoleFilter(value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Roles')),
              const PopupMenuItem(value: 'user', child: Text('User')),
              const PopupMenuItem(value: 'admin', child: Text('Admin')),
              const PopupMenuItem(value: 'super_admin', child: Text('Super Admin')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadUsers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Active Filter Display
          if (state.roleFilter != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceVariant,
              child: Row(
                children: [
                  const Text('Filter: '),
                  Chip(
                    label: Text('Role: ${state.roleFilter}'),
                    onDeleted: () => notifier.setRoleFilter(null),
                  ),
                ],
              ),
            ),

          // Users List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.users.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No users found', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          final user = state.users[index];
                          return _UserCard(
                            user: user,
                            onRoleChange: (newRole) async {
                              await notifier.updateUserRole(user.userId, newRole);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Role updated to $newRole')),
                                );
                              }
                            },
                            onStatusChange: (isActive) async {
                              await notifier.updateUserStatus(user.userId, isActive);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('User ${isActive ? "enabled" : "disabled"}'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),

          // Pagination
          if (state.pagination.totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.pagination.page > 1
                        ? () => notifier.loadUsers(page: state.pagination.page - 1)
                        : null,
                  ),
                  Text(
                    'Page ${state.pagination.page} of ${state.pagination.totalPages}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.pagination.page < state.pagination.totalPages
                        ? () => notifier.loadUsers(page: state.pagination.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final user;
  final Function(String) onRoleChange;
  final Function(bool) onStatusChange;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
    required this.onStatusChange,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: _getRoleColor(user.role),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.userId.substring(0, 8),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(user.role.toUpperCase().replaceAll('_', ' ')),
              backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _getRoleColor(user.role),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            if (!user.isActive)
              Chip(
                label: const Text('DISABLED'),
                backgroundColor: Colors.grey.shade300,
                labelStyle: const TextStyle(fontSize: 10),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Joined: ${dateFormat.format(user.createdAt)}'),
            if (user.lastLoginAt != null)
              Text('Last login: ${dateFormat.format(user.lastLoginAt!)}')
            else
              const Text('Never logged in'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'toggle_status') {
              onStatusChange(!user.isActive);
            } else if (value.startsWith('role_')) {
              final newRole = value.substring(5);
              onRoleChange(newRole);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(user.isActive ? Icons.block : Icons.check),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Disable User' : 'Enable User'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'role_user',
              child: Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Set as User'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'role_admin',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings),
                  SizedBox(width: 8),
                  Text('Set as Admin'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'role_super_admin',
              child: Row(
                children: [
                  Icon(Icons.supervisor_account),
                  SizedBox(width: 8),
                  Text('Set as Super Admin'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

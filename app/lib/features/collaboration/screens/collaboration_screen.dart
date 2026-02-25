import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/collaboration_service.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';

class CollaborationScreen extends ConsumerStatefulWidget {
  const CollaborationScreen({super.key});

  @override
  ConsumerState<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends ConsumerState<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Tree Collaboration'),
        backgroundColor: kPrimaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Collaborators', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Shared Trees', icon: Icon(Icons.folder_shared, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollaboratorsTab(),
          _buildSharedTreesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showShareDialog(context),
              backgroundColor: kPrimaryColor,
              icon: const Icon(Icons.person_add),
              label: const Text('Share Tree'),
            )
          : null,
    );
  }

  Widget _buildCollaboratorsTab() {
    final collaboratorsAsync = ref.watch(treeCollaboratorsProvider);
    final myPermissionAsync = ref.watch(myPermissionLevelProvider);

    return myPermissionAsync.when(
      data: (myPermission) {
        final canManage = myPermission == PermissionLevel.admin;

        return collaboratorsAsync.when(
          data: (collaborators) {
            if (collaborators.isEmpty) {
              return _buildEmptyState(
                icon: Icons.people_outline,
                title: 'No Collaborators Yet',
                message: 'Share your tree with family members to collaborate!',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: collaborators.length,
              itemBuilder: (context, index) {
                final collaborator = collaborators[index];
                return _buildCollaboratorCard(collaborator, canManage);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSharedTreesTab() {
    final sharedTreesAsync = ref.watch(sharedTreesProvider);

    return sharedTreesAsync.when(
      data: (trees) {
        if (trees.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_shared,
            title: 'No Shared Trees',
            message: 'Trees shared with you will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: trees.length,
          itemBuilder: (context, index) {
            final tree = trees[index];
            return _buildSharedTreeCard(tree);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildCollaboratorCard(Map<String, dynamic> collaborator, bool canManage) {
    final name = collaborator['name'] as String? ?? 'Unknown';
    final email = collaborator['email'] as String?;
    final phone = collaborator['phone'] as String?;
    final permissionStr = collaborator['permission_level'] as String? ?? 'viewer';
    final isOwner = collaborator['is_owner'] as bool? ?? false;
    final userId = collaborator['user_id'] as String?;

    final permission = _parsePermissionLevel(permissionStr);
    final permissionColor = _getPermissionColor(permission);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: permissionColor.withOpacity(0.2),
          child: Icon(_getPermissionIcon(permission), color: permissionColor),
        ),
        title: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isOwner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'OWNER',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null) Text(email),
            if (phone != null) Text(phone),
            const SizedBox(height: 4),
            _buildPermissionBadge(permission),
          ],
        ),
        trailing: canManage && !isOwner && userId != null
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleCollaboratorAction(value, userId, permission),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_permission',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Change Permission'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, size: 20, color: kErrorColor),
                        SizedBox(width: 8),
                        Text('Remove Access', style: TextStyle(color: kErrorColor)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildSharedTreeCard(Map<String, dynamic> tree) {
    final ownerName = tree['owner_name'] as String? ?? 'Unknown';
    final memberCount = tree['member_count'] as int? ?? 0;
    final permissionStr = tree['my_permission'] as String? ?? 'viewer';
    final treeId = tree['tree_id'] as String?;

    final permission = _parsePermissionLevel(permissionStr);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: kPrimaryColor,
          child: Icon(Icons.account_tree, color: Colors.white),
        ),
        title: Text(
          "$ownerName's Family Tree",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$memberCount members'),
            const SizedBox(height: 4),
            _buildPermissionBadge(permission),
          ],
        ),
        trailing: treeId != null
            ? ElevatedButton(
                onPressed: () => _switchToTree(treeId),
                child: const Text('Switch'),
              )
            : null,
      ),
    );
  }

  Widget _buildPermissionBadge(PermissionLevel permission) {
    final color = _getPermissionColor(permission);
    String label;
    
    switch (permission) {
      case PermissionLevel.admin:
        label = 'Admin';
        break;
      case PermissionLevel.editor:
        label = 'Editor';
        break;
      case PermissionLevel.viewer:
        label = 'Viewer';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: kTextSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  PermissionLevel _parsePermissionLevel(String str) {
    switch (str.toLowerCase()) {
      case 'admin':
        return PermissionLevel.admin;
      case 'editor':
        return PermissionLevel.editor;
      default:
        return PermissionLevel.viewer;
    }
  }

  Color _getPermissionColor(PermissionLevel permission) {
    switch (permission) {
      case PermissionLevel.admin:
        return Colors.red;
      case PermissionLevel.editor:
        return Colors.blue;
      case PermissionLevel.viewer:
        return Colors.green;
    }
  }

  IconData _getPermissionIcon(PermissionLevel permission) {
    switch (permission) {
      case PermissionLevel.admin:
        return Icons.admin_panel_settings;
      case PermissionLevel.editor:
        return Icons.edit;
      case PermissionLevel.viewer:
        return Icons.visibility;
    }
  }

  void _handleCollaboratorAction(String action, String userId, PermissionLevel currentPermission) {
    if (action == 'change_permission') {
      _showChangePermissionDialog(userId, currentPermission);
    } else if (action == 'remove') {
      _showRemoveCollaboratorDialog(userId);
    }
  }

  Future<void> _showShareDialog(BuildContext context) async {
    final identifierController = TextEditingController();
    final messageController = TextEditingController();
    PermissionLevel selectedPermission = PermissionLevel.viewer;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Share Tree'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: identifierController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Phone',
                    hintText: 'Enter email or phone number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<PermissionLevel>(
                  value: selectedPermission,
                  decoration: const InputDecoration(
                    labelText: 'Permission Level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: PermissionLevel.viewer, child: Text('Viewer (read-only)')),
                    DropdownMenuItem(value: PermissionLevel.editor, child: Text('Editor (can edit)')),
                    DropdownMenuItem(value: PermissionLevel.admin, child: Text('Admin (full access)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPermission = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    hintText: 'Add a personal message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                if (identifierController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter email or phone')),
                  );
                  return;
                }

                try {
                  await ref.read(collaborationServiceProvider).shareTree(
                        identifier: identifierController.text.trim(),
                        permission: selectedPermission,
                        message: messageController.text.isEmpty ? null : messageController.text,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tree shared successfully!')),
                    );
                    ref.invalidate(treeCollaboratorsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePermissionDialog(String userId, PermissionLevel currentPermission) async {
    PermissionLevel newPermission = currentPermission;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Permission'),
          content: DropdownButtonFormField<PermissionLevel>(
            value: newPermission,
            decoration: const InputDecoration(
              labelText: 'New Permission Level',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: PermissionLevel.viewer, child: Text('Viewer')),
              DropdownMenuItem(value: PermissionLevel.editor, child: Text('Editor')),
              DropdownMenuItem(value: PermissionLevel.admin, child: Text('Admin')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => newPermission = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(collaborationServiceProvider).updateCollaboratorPermission(
                        userId,
                        newPermission,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permission updated!')),
                    );
                    ref.invalidate(treeCollaboratorsProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveCollaboratorDialog(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Collaborator'),
        content: const Text('Are you sure you want to remove this person\'s access to the tree?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(collaborationServiceProvider).removeCollaborator(userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collaborator removed')),
          );
          ref.invalidate(treeCollaboratorsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _switchToTree(String treeId) async {
    try {
      await ref.read(collaborationServiceProvider).switchTree(treeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Switched to shared tree')),
        );
        // Refresh all data providers
        ref.invalidate(treeCollaboratorsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Permission levels for tree collaboration
enum PermissionLevel {
  viewer,  // Can only view
  editor,  // Can add/edit members
  admin,   // Full control including sharing
}

/// Service for managing tree sharing and collaboration
class CollaborationService {
  final ApiService _apiService;

  CollaborationService(this._apiService);

  /// Get all people who have access to the tree
  Future<List<Map<String, dynamic>>> getTreeCollaborators() async {
    final response = await _apiService.get('/api/tree/collaborators');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Share tree with a user by email or phone
  Future<Map<String, dynamic>> shareTree({
    required String identifier, // email or phone
    required PermissionLevel permission,
    String? message,
  }) async {
    final response = await _apiService.post('/api/tree/share', {
      'identifier': identifier,
      'permission_level': permission.name,
      'message': message,
    });
    return response;
  }

  /// Update collaborator's permission level
  Future<void> updateCollaboratorPermission(
    String userId,
    PermissionLevel newPermission,
  ) async {
    await _apiService.put('/api/tree/collaborators/$userId', {
      'permission_level': newPermission.name,
    });
  }

  /// Remove collaborator access
  Future<void> removeCollaborator(String userId) async {
    await _apiService.delete('/api/tree/collaborators/$userId');
  }

  /// Get pending share invitations
  Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    final response = await _apiService.get('/api/tree/invitations/pending');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Accept a tree share invitation
  Future<void> acceptInvitation(String invitationId) async {
    await _apiService.post('/api/tree/invitations/$invitationId/accept', {});
  }

  /// Decline a tree share invitation
  Future<void> declineInvitation(String invitationId) async {
    await _apiService.post('/api/tree/invitations/$invitationId/decline', {});
  }

  /// Get trees shared with me
  Future<List<Map<String, dynamic>>> getSharedTrees() async {
    final response = await _apiService.get('/api/tree/shared-with-me');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Switch to a different tree
  Future<void> switchTree(String treeId) async {
    await _apiService.post('/api/tree/switch/$treeId', {});
  }

  /// Get current user's permission level on the tree
  Future<PermissionLevel> getMyPermissionLevel() async {
    final response = await _apiService.get('/api/tree/my-permission');
    final levelStr = response['permission_level'] as String? ?? 'viewer';
    
    switch (levelStr) {
      case 'admin':
        return PermissionLevel.admin;
      case 'editor':
        return PermissionLevel.editor;
      default:
        return PermissionLevel.viewer;
    }
  }
}

/// Provider for CollaborationService
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CollaborationService(apiService);
});

/// Provider for tree collaborators
final treeCollaboratorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  return service.getTreeCollaborators();
});

/// Provider for pending invitations
final pendingInvitationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  return service.getPendingInvitations();
});

/// Provider for shared trees
final sharedTreesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  return service.getSharedTrees();
});

/// Provider for current user's permission level
final myPermissionLevelProvider = FutureProvider<PermissionLevel>((ref) async {
  final service = ref.watch(collaborationServiceProvider);
  return service.getMyPermissionLevel();
});

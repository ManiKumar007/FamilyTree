import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../config/theme.dart';
import '../widgets/person_card.dart';
import '../widgets/tree_painter.dart';

/// The main tree view screen with a Geni-style pannable/zoomable canvas.
class TreeViewScreen extends ConsumerStatefulWidget {
  const TreeViewScreen({super.key});

  @override
  ConsumerState<TreeViewScreen> createState() => _TreeViewScreenState();
}

class _TreeViewScreenState extends ConsumerState<TreeViewScreen> {
  final TransformationController _transformController = TransformationController();
  bool _checkingProfile = true;
  
  @override
  void initState() {
    super.initState();
    _checkProfileSetup();
  }

  Future<void> _checkProfileSetup() async {
    // Check if user has completed profile setup
    final profile = await ref.read(myProfileProvider.future);
    // Don't automatically redirect - let user see tree view even if profile is not set up
    // The empty tree view will show a prompt to set up profile
    if (mounted) {
      setState(() { _checkingProfile = false; });
    }
  }

  void _centerOnUser() {
    _transformController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking if profile is set up
    if (_checkingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final treeAsync = ref.watch(familyTreeProvider);
    final pendingMerges = ref.watch(pendingMergesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_tree_rounded, size: 22, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('Family Tree'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withOpacity(0.5)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tree',
            onPressed: () {
              ref.invalidate(familyTreeProvider);
              ref.invalidate(myProfileProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () {
              // Navigate to profile using provider that handles async
              ref.read(myProfileProvider.future).then((profile) {
                if (profile != null && context.mounted) {
                  // Profile exists, go to detail page
                  context.push('/person/${profile.id}');
                } else if (context.mounted) {
                  // No profile yet, go to profile setup
                  context.push('/profile-setup');
                }
              }).catchError((error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading profile: $error')),
                  );
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: kErrorColor),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Main tree canvas
          treeAsync.when(
            data: (tree) {
              if (tree == null || tree.nodes.isEmpty) {
                return _emptyTreeView();
              }
              return _buildTreeCanvas(tree, currentUserId);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: kErrorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tree',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kErrorColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(familyTreeProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Merge notification banner
          pendingMerges.when(
            data: (merges) {
              if (merges.isEmpty) return const SizedBox.shrink();
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: kAccentColor.withOpacity(0.9),
                    child: Row(
                      children: [
                        const Icon(Icons.merge_type, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${merges.length} possible connection(s) found!',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/merge/${merges.first.id}'),
                          child: const Text('Review', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Navigation controls (bottom-left)
          Positioned(
            bottom: 24,
            left: 16,
            child: Column(
              children: [
                _navButton(Icons.keyboard_arrow_up, () {
                  final matrix = _transformController.value.clone();
                  matrix.translate(0.0, 100.0);
                  _transformController.value = matrix;
                }),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navButton(Icons.keyboard_arrow_left, () {
                      final matrix = _transformController.value.clone();
                      matrix.translate(100.0, 0.0);
                      _transformController.value = matrix;
                    }),
                    _navButton(Icons.center_focus_strong, _centerOnUser),
                    _navButton(Icons.keyboard_arrow_right, () {
                      final matrix = _transformController.value.clone();
                      matrix.translate(-100.0, 0.0);
                      _transformController.value = matrix;
                    }),
                  ],
                ),
                _navButton(Icons.keyboard_arrow_down, () {
                  final matrix = _transformController.value.clone();
                  matrix.translate(0.0, -100.0);
                  _transformController.value = matrix;
                }),
              ],
            ),
          ),

          // Zoom controls (bottom-right)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                _navButton(Icons.zoom_in, () {
                  final matrix = _transformController.value.clone();
                  matrix.scale(1.2);
                  _transformController.value = matrix;
                }),
                const SizedBox(height: 4),
                _navButton(Icons.zoom_out, () {
                  final matrix = _transformController.value.clone();
                  matrix.scale(0.8);
                  _transformController.value = matrix;
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tree/add-member'),
        tooltip: 'Add Family Member',
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _emptyTreeView() {
    final profileAsync = ref.watch(myProfileProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 80, color: kTextDisabled),
          const SizedBox(height: 16),
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                // No profile - show setup prompt
                return Column(
                  children: [
                    Text(
                      'Welcome to MyFamilyTree!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile to start building your family tree.',
                      style: TextStyle(color: kTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/profile-setup'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Set Up My Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                );
              }
              // Has profile but tree is empty
              return Column(
                children: [
                  Text(
                    'Your family tree is empty',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding your parents, siblings, or spouse.',
                    style: TextStyle(color: kTextSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/tree/add-member'),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Family Member'),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Column(
              children: [
                Text(
                  'Error loading profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kErrorColor),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: TextStyle(color: kTextSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.push('/profile-setup'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Set Up Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCanvas(TreeResponse tree, String? userId) {
    // Build layout: organize nodes by generation (depth from root)
    final layout = _calculateLayout(tree, userId);

    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(2000),
      minScale: 0.1,
      maxScale: 3.0,
      constrained: false,
      child: SizedBox(
        width: layout.canvasWidth,
        height: layout.canvasHeight,
        child: Stack(
          children: [
            // Connection lines
            CustomPaint(
              size: Size(layout.canvasWidth, layout.canvasHeight),
              painter: TreeLinePainter(lines: layout.lines),
            ),
            // Person cards
            ...layout.positionedNodes.map((pn) => Positioned(
              left: pn.x,
              top: pn.y,
              child: PersonCard(
                person: pn.person,
                isCurrentUser: pn.person.id == tree.rootPersonId,
                onTap: () => context.push('/person/${pn.person.id}'),
                onEdit: pn.canEdit
                    ? () => context.push('/edit-profile/${pn.person.id}')
                    : null,
                onInvite: !pn.person.verified
                    ? () => _showInviteDialog(pn.person)
                    : null,
              ),
            )),
            // Add buttons for missing relatives
            ...layout.addButtons.map((btn) => Positioned(
              left: btn.x,
              top: btn.y,
              child: AddPersonButton(
                label: btn.label,
                onTap: () {
                  _showRelationshipPicker(btn.relativePersonId);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showAddParentChoice(String relativePersonId) {
    _showRelationshipPicker(relativePersonId);
  }

  void _showRelationshipPicker(String relativePersonId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Family Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Parents Row
                Row(
                children: [
                  Expanded(
                    child: _relationshipButton(
                      'Add Father',
                      Icons.person,
                      kMaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'FATHER_OF',
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _relationshipButton(
                      'Add Mother',
                      Icons.person,
                      kFemaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'MOTHER_OF',
                        });
                      },
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 10),
                
                // Siblings Row
                Row(
                children: [
                  Expanded(
                    child: _relationshipButton(
                      'Add Brother',
                      Icons.person,
                      kMaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'SIBLING_OF',
                          'gender': 'male',
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _relationshipButton(
                      'Add Sister',
                      Icons.person,
                      kFemaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'SIBLING_OF',
                          'gender': 'female',
                        });
                      },
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 10),
                
                // Spouse Row
                Row(
                children: [
                  Expanded(
                    child: _relationshipButton(
                      'Add Husband',
                      Icons.person,
                      kMaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'SPOUSE_OF',
                          'gender': 'male',
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _relationshipButton(
                      'Add Wife',
                      Icons.person,
                      kFemaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'SPOUSE_OF',
                          'gender': 'female',
                        });
                      },
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 10),
                
                // Children Row
                Row(
                children: [
                  Expanded(
                    child: _relationshipButton(
                      'Add Son',
                      Icons.person,
                      kMaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'CHILD_OF',
                          'gender': 'male',
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _relationshipButton(
                      'Add Daughter',
                      Icons.person,
                      kFemaleColor,
                      () {
                        Navigator.pop(ctx);
                        context.push('/tree/add-member', extra: {
                          'relativePersonId': relativePersonId,
                          'relationshipType': 'CHILD_OF',
                          'gender': 'female',
                        });
                      },
                    ),
                  ),
                ],
                ),
                const SizedBox(height: 16),
                
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _relationshipButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteDialog(Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invite ${person.name}?'),
        content: Text(
          'Send an invite to ${person.name} (${person.phone}) to join MyFamilyTree and claim their profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/invite');
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: kDividerColor),
          ),
          child: Icon(icon, size: 20, color: kTextSecondary),
        ),
      ),
    );
  }

  /// Calculate positions for all nodes in the tree.
  /// Uses a simple generation-based layout algorithm.
  _TreeLayout _calculateLayout(TreeResponse tree, String? userId) {
    final nodes = tree.nodes;
    final rootId = tree.rootPersonId;
    
    // Build adjacency maps
    final personMap = <String, Person>{};
    final childrenOf = <String, List<String>>{}; // parent -> children
    final spouseOf = <String, String?>{}; // person -> spouse
    final parentOf = <String, List<String>>{}; // child -> parents
    
    for (final node in nodes) {
      personMap[node.person.id] = node.person;
      for (final rel in node.relationships) {
        if (rel.type == 'FATHER_OF' || rel.type == 'MOTHER_OF') {
          childrenOf.putIfAbsent(node.person.id, () => []);
          childrenOf[node.person.id]!.add(rel.relatedPersonId);
        } else if (rel.type == 'SPOUSE_OF') {
          spouseOf[node.person.id] = rel.relatedPersonId;
        } else if (rel.type == 'CHILD_OF') {
          parentOf.putIfAbsent(node.person.id, () => []);
          parentOf[node.person.id]!.add(rel.relatedPersonId);
        }
      }
    }

    // BFS to assign generations (depth levels)
    final generations = <String, int>{};
    final visited = <String>{};
    final queue = <String>[rootId];
    generations[rootId] = 2; // Start at generation 2 to leave room for parents above

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      visited.add(current);

      final gen = generations[current] ?? 2;
      
      // Parents are one generation above
      final parents = parentOf[current] ?? [];
      for (final p in parents) {
        if (!visited.contains(p)) {
          generations[p] = gen - 1;
          queue.add(p);
        }
      }
      
      // Children are one generation below
      final children = childrenOf[current] ?? [];
      for (final c in children) {
        if (!visited.contains(c)) {
          generations[c] = gen + 1;
          queue.add(c);
        }
      }
      
      // Spouses are same generation
      final spouse = spouseOf[current];
      if (spouse != null && !visited.contains(spouse)) {
        generations[spouse] = gen;
        queue.add(spouse);
      }
    }

    // Group by generation
    final genGroups = <int, List<String>>{};
    for (final entry in generations.entries) {
      genGroups.putIfAbsent(entry.value, () => []);
      genGroups[entry.value]!.add(entry.key);
    }

    // Calculate positions
    const cardWidth = 140.0;
    const cardHeight = 120.0;
    const hGap = 30.0;
    const vGap = 80.0;
    const padding = 200.0;

    final positionedNodes = <_PositionedNode>[];
    final nodePositions = <String, Offset>{};
    final lines = <ConnectionLine>[];

    final sortedGens = genGroups.keys.toList()..sort();
    
    for (final gen in sortedGens) {
      final members = genGroups[gen]!;
      final y = padding + (gen * (cardHeight + vGap));
      
      for (int i = 0; i < members.length; i++) {
        final x = padding + (i * (cardWidth + hGap));
        final personId = members[i];
        final person = personMap[personId];
        
        if (person != null) {
          nodePositions[personId] = Offset(x + cardWidth / 2, y + cardHeight / 2);
          positionedNodes.add(_PositionedNode(
            person: person,
            x: x,
            y: y,
            canEdit: person.createdByUserId == userId || person.authUserId == userId,
          ));
        }
      }
    }

    // Draw connection lines
    for (final node in nodes) {
      final fromPos = nodePositions[node.person.id];
      if (fromPos == null) continue;

      for (final rel in node.relationships) {
        final toPos = nodePositions[rel.relatedPersonId];
        if (toPos == null) continue;

        if (rel.type == 'SPOUSE_OF') {
          // Horizontal line for spouse
          lines.add(ConnectionLine(
            start: fromPos,
            end: toPos,
            type: LineType.straight,
          ));
        } else if (rel.type == 'FATHER_OF' || rel.type == 'MOTHER_OF') {
          // Elbow line from parent to child
          lines.add(ConnectionLine(
            start: Offset(fromPos.dx, fromPos.dy + cardHeight / 2),
            end: Offset(toPos.dx, toPos.dy - cardHeight / 2),
            type: LineType.elbow,
          ));
        }
      }
    }

    // Add buttons for missing relatives — for EVERY node, not just root
    final addButtons = <_AddButton>[];
    
    for (final node in nodes) {
      final personId = node.person.id;
      final pos = nodePositions[personId];
      if (pos == null) continue;

      final parents = parentOf[personId] ?? [];
      final children = childrenOf[personId] ?? [];
      
      // Determine which parent types exist
      bool hasFather = false;
      bool hasMother = false;
      for (final parentId in parents) {
        final parent = personMap[parentId];
        if (parent != null) {
          if (parent.gender == 'male') hasFather = true;
          if (parent.gender == 'female') hasMother = true;
        }
      }
      
      // Only show parent buttons if no parents yet (avoids overlapping)
      if (!hasFather && !hasMother) {
        // Show a single "Add Parents" button above
        addButtons.add(_AddButton(
          x: pos.dx - cardWidth / 2,
          y: pos.dy - cardHeight / 2 - cardHeight - vGap + 20,
          label: 'Add Parents',
          relativePersonId: personId,
          relationshipType: '_PARENTS_',  // special sentinel
        ));
      } else {
        // Show individual missing parent
        if (!hasFather) {
          // Place to the left of existing mother
          final motherPos = parents
              .where((p) => personMap[p]?.gender == 'female')
              .map((p) => nodePositions[p])
              .firstOrNull;
          final fx = motherPos != null
              ? motherPos.dx - cardWidth - hGap
              : pos.dx - cardWidth / 2 - cardWidth / 2 - hGap;
          final fy = motherPos != null
              ? motherPos.dy - cardHeight / 2
              : pos.dy - cardHeight / 2 - cardHeight - vGap;
          addButtons.add(_AddButton(
            x: fx,
            y: fy,
            label: 'Add Father',
            relativePersonId: personId,
            relationshipType: 'FATHER_OF',
          ));
        }
        if (!hasMother) {
          final fatherPos = parents
              .where((p) => personMap[p]?.gender == 'male')
              .map((p) => nodePositions[p])
              .firstOrNull;
          final mx = fatherPos != null
              ? fatherPos.dx + cardWidth + hGap
              : pos.dx + cardWidth / 2 + hGap;
          final my = fatherPos != null
              ? fatherPos.dy - cardHeight / 2
              : pos.dy - cardHeight / 2 - cardHeight - vGap;
          addButtons.add(_AddButton(
            x: mx,
            y: my,
            label: 'Add Mother',
            relativePersonId: personId,
            relationshipType: 'MOTHER_OF',
          ));
        }
      }

      // Spouse — only show if no spouse yet
      if (spouseOf[personId] == null) {
        addButtons.add(_AddButton(
          x: pos.dx + cardWidth / 2 + hGap,
          y: pos.dy - cardHeight / 2,
          label: 'Add Spouse',
          relativePersonId: personId,
          relationshipType: 'SPOUSE_OF',
        ));
      }

      // Sibling — show a small "Add Sibling" to the right of this person
      // (only if they have at least one parent, so the sibling connects correctly)
      if (parents.isNotEmpty) {
        addButtons.add(_AddButton(
          x: pos.dx + cardWidth / 2 + hGap + (spouseOf[personId] != null ? cardWidth + hGap : 0),
          y: pos.dy - cardHeight / 2,
          label: 'Add Sibling',
          relativePersonId: personId,
          relationshipType: 'SIBLING_OF',
        ));
      }

      // Child — show below
      if (children.isEmpty) {
        addButtons.add(_AddButton(
          x: pos.dx - cardWidth / 2 + (cardWidth - 120) / 2,
          y: pos.dy + cardHeight / 2 + vGap,
          label: 'Add Child',
          relativePersonId: personId,
          relationshipType: 'CHILD_OF',
        ));
      }
    }

    // Calculate canvas size
    double maxX = 0, maxY = 0;
    for (final pn in positionedNodes) {
      if (pn.x + cardWidth > maxX) maxX = pn.x + cardWidth;
      if (pn.y + cardHeight > maxY) maxY = pn.y + cardHeight;
    }

    return _TreeLayout(
      positionedNodes: positionedNodes,
      addButtons: addButtons,
      lines: lines,
      canvasWidth: maxX + padding * 2,
      canvasHeight: maxY + padding * 2,
    );
  }
}

class _PositionedNode {
  final Person person;
  final double x;
  final double y;
  final bool canEdit;

  const _PositionedNode({
    required this.person,
    required this.x,
    required this.y,
    required this.canEdit,
  });
}

class _AddButton {
  final double x;
  final double y;
  final String label;
  final String relativePersonId;
  final String relationshipType;

  const _AddButton({
    required this.x,
    required this.y,
    required this.label,
    required this.relativePersonId,
    required this.relationshipType,
  });
}

class _TreeLayout {
  final List<_PositionedNode> positionedNodes;
  final List<_AddButton> addButtons;
  final List<ConnectionLine> lines;
  final double canvasWidth;
  final double canvasHeight;

  const _TreeLayout({
    required this.positionedNodes,
    required this.addButtons,
    required this.lines,
    required this.canvasWidth,
    required this.canvasHeight,
  });
}

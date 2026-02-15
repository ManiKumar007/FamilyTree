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
  
  @override
  void initState() {
    super.initState();
    _checkProfileSetup();
  }

  Future<void> _checkProfileSetup() async {
    // Check if user has completed profile setup
    final profile = await ref.read(myProfileProvider.future);
    if (profile == null && mounted) {
      context.go('/profile-setup');
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
    final treeAsync = ref.watch(familyTreeProvider);
    final pendingMerges = ref.watch(pendingMergesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyFamilyTree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Network',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () async {
              final profile = await ref.read(myProfileProvider.future);
              if (profile != null && context.mounted) {
                context.push('/person/${profile.id}');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
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
              return _buildTreeCanvas(tree);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading tree: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(familyTreeProvider),
                    child: const Text('Retry'),
                  ),
                ],
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
        onPressed: () => context.push('/add-member'),
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _emptyTreeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Your family tree is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your parents, siblings, or spouse.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-member'),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Family Member'),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeCanvas(TreeResponse tree) {
    // Build layout: organize nodes by generation (depth from root)
    final layout = _calculateLayout(tree);

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
                onTap: () => context.push('/add-member', extra: {
                  'relativePersonId': btn.relativePersonId,
                  'relationshipType': btn.relationshipType,
                }),
              ),
            )),
          ],
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
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }

  /// Calculate positions for all nodes in the tree.
  /// Uses a simple generation-based layout algorithm.
  _TreeLayout _calculateLayout(TreeResponse tree) {
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
            canEdit: true, // Simplified — in production check created_by
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

    // Add buttons for missing relatives
    final addButtons = <_AddButton>[];
    final rootPerson = personMap[rootId];
    if (rootPerson != null) {
      final rootPos = nodePositions[rootId];
      if (rootPos != null) {
        // Check for missing parents
        final rootParents = parentOf[rootId] ?? [];
        if (rootParents.isEmpty || rootParents.length < 2) {
          addButtons.add(_AddButton(
            x: rootPos.dx - cardWidth / 2 - cardWidth - hGap,
            y: rootPos.dy - cardHeight / 2 - cardHeight - vGap,
            label: 'Add Father',
            relativePersonId: rootId,
            relationshipType: 'FATHER_OF',
          ));
          addButtons.add(_AddButton(
            x: rootPos.dx - cardWidth / 2 + cardWidth + hGap,
            y: rootPos.dy - cardHeight / 2 - cardHeight - vGap,
            label: 'Add Mother',
            relativePersonId: rootId,
            relationshipType: 'MOTHER_OF',
          ));
        }

        // Check for missing spouse
        if (spouseOf[rootId] == null) {
          addButtons.add(_AddButton(
            x: rootPos.dx + cardWidth / 2 + hGap,
            y: rootPos.dy - cardHeight / 2,
            label: 'Add Spouse',
            relativePersonId: rootId,
            relationshipType: 'SPOUSE_OF',
          ));
        }

        // Add child button
        addButtons.add(_AddButton(
          x: rootPos.dx - cardWidth / 2,
          y: rootPos.dy + cardHeight / 2 + vGap,
          label: 'Add Child',
          relativePersonId: rootId,
          relationshipType: 'CHILD_OF', // The new person is CHILD_OF root
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

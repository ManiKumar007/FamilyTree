import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/whatsapp_share_service.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';
import '../../../widgets/app_shell.dart';
import '../widgets/person_card.dart';
import '../widgets/tree_painter.dart';
import '../widgets/add_family_dialog.dart';

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
    // Pre-fetch profile data (non-blocking) so it's ready when tree loads
    Future.microtask(() {
      ref.read(myProfileProvider.future).timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      ).catchError((_) => null);
    });
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
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.of(context).size.width < AppSizing.breakpointTablet
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => mobileShellScaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: Row(
          children: [
            Icon(Icons.account_tree_rounded, size: 22, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('Family Tree'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withValues(alpha: 0.5)),
        ),
        actions: [
          // WhatsApp share button
          treeAsync.maybeWhen(
            data: (tree) => tree != null && tree.nodes.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Share on WhatsApp',
                    color: const Color(0xFF25D366), // WhatsApp green
                    onPressed: () {
                      final memberCount = tree.nodes.length;
                      final message = WhatsAppShareService.generateTreeSizeMilestone(memberCount);
                      WhatsAppShareService.shareMilestone(message);
                      
                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Opening WhatsApp...'),
                            ],
                          ),
                          backgroundColor: Color(0xFF25D366),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                : null,
            orElse: () => null,
          ),
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
                    color: kAccentColor.withValues(alpha: 0.9),
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
        onPressed: () async {
          final profile = await ref.read(myProfileProvider.future);
          if (profile != null && mounted) {
            showAddFamilyDialog(context, profile);
          } else if (mounted) {
            context.push('/profile-setup');
          }
        },
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
    final r = Responsive(context);

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
                cardWidth: r.treeCardWidth,
                onTap: () => context.push('/person/${pn.person.id}'),
                onEdit: pn.canEdit
                    ? () => context.push('/edit-profile/${pn.person.id}')
                    : null,
                onInvite: !pn.person.verified
                    ? () => _showInviteDialog(pn.person)
                    : null,
                onFindConnection: pn.person.username != null
                    ? () => _navigateToConnectionFinder(pn.person.username!)
                    : null,
                onAddFamily: () => showAddFamilyDialog(context, pn.person),
                onDelete: pn.person.id != tree.rootPersonId
                    ? () => _showDeleteDialog(pn.person)
                    : null,
              ),
            )),
            // Add buttons for missing relatives - REMOVED: Use + button on cards instead
            // ...layout.addButtons.map((btn) => Positioned(
            //   left: btn.x,
            //   top: btn.y,
            //   child: AddPersonButton(
            //     label: btn.label,
            //     buttonWidth: r.treeAddBtnWidth,
            //     onTap: () {
            //       _showRelationshipPicker(btn.relativePersonId);
            //     },
            //   ),
            // )),
          ],
        ),
      ),
    );
  }

  void _showRelationshipPicker(String relativePersonId) {
    // Find the person from the tree
    final treeAsync = ref.read(familyTreeProvider);
    treeAsync.whenData((tree) {
      if (tree != null) {
        final personNode = tree.nodes.firstWhere(
          (node) => node.person.id == relativePersonId,
          orElse: () => tree.nodes.first,
        );
        if (mounted) {
          showAddFamilyDialog(context, personNode.person);
        }
      }
    });
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

  void _showDeleteDialog(Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text(
          'Are you sure you want to delete ${person.name} from the family tree? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(apiServiceProvider).deletePerson(person.id);
                // Refresh the tree
                ref.invalidate(familyTreeProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${person.name} has been deleted'),
                      backgroundColor: kSuccessColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: kErrorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToConnectionFinder(String username) {
    // Navigate to connection finder screen with the username pre-filled
    // The connection finder screen will auto-fill the user's own username
    // and paste the clicked person's username in the second field
    context.push('/connection?target=$username');
  }

  Widget _navButton(IconData icon, VoidCallback onPressed) {
    final r = Responsive(context);
    final btnSize = r.value(mobile: 34.0, desktop: 40.0);
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: kDividerColor),
          ),
          child: Icon(icon, size: btnSize * 0.5, color: kTextSecondary),
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
          // This person is parent of relatedPerson
          childrenOf.putIfAbsent(node.person.id, () => []);
          if (!childrenOf[node.person.id]!.contains(rel.relatedPersonId)) {
            childrenOf[node.person.id]!.add(rel.relatedPersonId);
          }
          // Also record the reverse: relatedPerson has this person as parent
          parentOf.putIfAbsent(rel.relatedPersonId, () => []);
          if (!parentOf[rel.relatedPersonId]!.contains(node.person.id)) {
            parentOf[rel.relatedPersonId]!.add(node.person.id);
          }
        } else if (rel.type == 'SPOUSE_OF') {
          // Make spouse map bidirectional so both partners know about each other
          spouseOf[node.person.id] = rel.relatedPersonId;
          spouseOf[rel.relatedPersonId] ??= node.person.id;
        } else if (rel.type == 'CHILD_OF') {
          // This person is child of relatedPerson
          parentOf.putIfAbsent(node.person.id, () => []);
          if (!parentOf[node.person.id]!.contains(rel.relatedPersonId)) {
            parentOf[node.person.id]!.add(rel.relatedPersonId);
          }
          // Also record the reverse: relatedPerson has this person as child
          childrenOf.putIfAbsent(rel.relatedPersonId, () => []);
          if (!childrenOf[rel.relatedPersonId]!.contains(node.person.id)) {
            childrenOf[rel.relatedPersonId]!.add(node.person.id);
          }
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

    // Calculate positions with better family grouping
    final r = Responsive(context);
    final cardWidth = r.treeCardWidth;
    final addBtnWidth = r.treeAddBtnWidth;
    final cardHeight = r.treeCardHeight;
    final hGap = r.treeHGap;
    final spouseGap = r.treeSpouseGap;
    final vGap = r.treeVGap;
    final padding = r.treePadding;

    final positionedNodes = <_PositionedNode>[];
    final nodePositions = <String, Offset>{};
    final lines = <ConnectionLine>[];
    final positioned = <String>{};

    // === Recursive layout: center children under their parent couple ===

    // Helper: Get deduplicated children of a person (merging both parents in a couple)
    List<String> getChildrenOf(String personId) {
      final result = <String>{};
      result.addAll(childrenOf[personId] ?? []);
      final sid = spouseOf[personId];
      if (sid != null) {
        result.addAll(childrenOf[sid] ?? []);
      }
      return result.toList();
    }

    // Bottom-up: compute the width each subtree needs
    final Map<String, double> _stCache = {};
    final Set<String> _stVisited = {};

    double getSubtreeWidth(String personId) {
      if (_stCache.containsKey(personId)) return _stCache[personId]!;
      if (_stVisited.contains(personId)) {
        final sid = spouseOf[personId];
        return (sid != null && personMap.containsKey(sid))
            ? (cardWidth * 2 + spouseGap)
            : cardWidth;
      }
      _stVisited.add(personId);

      final sid = spouseOf[personId];
      final hasSpouse = sid != null && personMap.containsKey(sid);
      final coupleW = hasSpouse ? (cardWidth * 2 + spouseGap) : cardWidth;

      final kids = getChildrenOf(personId);
      if (kids.isEmpty) {
        _stCache[personId] = coupleW;
        if (hasSpouse) _stCache[sid!] = coupleW;
        return coupleW;
      }

      double kidsW = 0;
      for (final kid in kids) {
        kidsW += getSubtreeWidth(kid);
      }
      kidsW += (kids.length - 1) * hGap;

      final w = kidsW > coupleW ? kidsW : coupleW;
      _stCache[personId] = w;
      if (hasSpouse) _stCache[sid!] = w;
      return w;
    }

    // Top-down: place each node (and its spouse) centred inside its subtree band
    void positionAt(String personId, double startX) {
      if (positioned.contains(personId)) return;
      final person = personMap[personId];
      if (person == null) return;

      final gen = generations[personId] ?? 2;
      final y = padding + gen * (cardHeight + vGap);

      final sid = spouseOf[personId];
      final hasSpouse = sid != null && personMap.containsKey(sid);
      final coupleW = hasSpouse ? (cardWidth * 2 + spouseGap) : cardWidth;
      final stw = getSubtreeWidth(personId);

      // Centre the couple inside its subtree band
      final coupleX = startX + (stw - coupleW) / 2;

      // Male on left, female on right
      String leftId = personId;
      String? rightId = hasSpouse ? sid : null;
      if (hasSpouse) {
        if (person.gender == 'female' && personMap[sid]?.gender == 'male') {
          leftId = sid!;
          rightId = personId;
        }
      }

      // Place left card
      if (!positioned.contains(leftId) && personMap.containsKey(leftId)) {
        nodePositions[leftId] = Offset(coupleX + cardWidth / 2, y + cardHeight / 2);
        positionedNodes.add(_PositionedNode(
          person: personMap[leftId]!,
          x: coupleX,
          y: y,
          canEdit: personMap[leftId]!.createdByUserId == userId ||
                   personMap[leftId]!.authUserId == userId,
        ));
        positioned.add(leftId);
      }

      // Place right card (spouse)
      if (rightId != null && !positioned.contains(rightId) && personMap.containsKey(rightId)) {
        final spX = coupleX + cardWidth + spouseGap;
        nodePositions[rightId] = Offset(spX + cardWidth / 2, y + cardHeight / 2);
        positionedNodes.add(_PositionedNode(
          person: personMap[rightId]!,
          x: spX,
          y: y,
          canEdit: personMap[rightId]!.createdByUserId == userId ||
                   personMap[rightId]!.authUserId == userId,
        ));
        positioned.add(rightId);
      }

      // Recursively position children, centred under this couple
      final kids = getChildrenOf(personId);
      if (kids.isNotEmpty) {
        double kidsW = 0;
        for (final kid in kids) {
          kidsW += getSubtreeWidth(kid);
        }
        kidsW += (kids.length - 1) * hGap;

        double kidX = startX + (stw - kidsW) / 2;
        for (final kid in kids) {
          positionAt(kid, kidX);
          kidX += getSubtreeWidth(kid) + hGap;
        }
      }
    }

    // Walk up from root to find the topmost ancestor
    String topAncestor = rootId;
    {
      final upVisited = <String>{rootId};
      var current = rootId;
      while (true) {
        final pars = parentOf[current] ?? [];
        final next = pars.where((p) => !upVisited.contains(p)).firstOrNull;
        if (next == null) break;
        upVisited.add(next);
        current = next;
      }
      topAncestor = current;
    }
    // Convention: if topmost ancestor is female with a male spouse, use the male
    if (personMap[topAncestor]?.gender == 'female') {
      final s = spouseOf[topAncestor];
      if (s != null && personMap[s]?.gender == 'male') topAncestor = s;
    }

    // Compute widths then position the main tree
    getSubtreeWidth(topAncestor);
    positionAt(topAncestor, padding);

    // Position any remaining nodes that weren't reached (e.g. in-law ancestors)
    for (final node in nodes) {
      if (!positioned.contains(node.person.id)) {
        double maxRight = padding;
        for (final pos in nodePositions.values) {
          final right = pos.dx + cardWidth / 2;
          if (right > maxRight) maxRight = right;
        }
        getSubtreeWidth(node.person.id);
        positionAt(node.person.id, maxRight + hGap);
      }
    }

    // === Connection lines: T-junction from couple to children ===
    final drawnCoupleLines = <String>{};

    for (final personId in positioned) {
      final pos = nodePositions[personId];
      if (pos == null) continue;

      final sid = spouseOf[personId];
      final spousePos = sid != null ? nodePositions[sid] : null;

      // --- Spouse line (once per couple) ---
      if (sid != null && spousePos != null) {
        final coupleKey = ([personId, sid]..sort()).join('|');
        if (!drawnCoupleLines.contains(coupleKey)) {
          drawnCoupleLines.add(coupleKey);
          final leftX = pos.dx < spousePos.dx ? pos.dx : spousePos.dx;
          final rightX = pos.dx > spousePos.dx ? pos.dx : spousePos.dx;
          lines.add(ConnectionLine(
            start: Offset(leftX + cardWidth / 2, pos.dy),
            end: Offset(rightX - cardWidth / 2, pos.dy),
            type: LineType.straight,
          ));
        }
      }

      // --- Parent-to-children T-junction (once per couple) ---
      final kids = getChildrenOf(personId);
      if (kids.isNotEmpty) {
        final coupleKey = sid != null
            ? ([personId, sid]..sort()).join('|')
            : personId;
        final linesKey = 'ch_$coupleKey';
        if (!drawnCoupleLines.contains(linesKey)) {
          drawnCoupleLines.add(linesKey);

          // Midpoint X between the couple (or single parent centre)
          double midX;
          if (spousePos != null) {
            midX = (pos.dx + spousePos.dx) / 2;
          } else {
            midX = pos.dx;
          }

          final parentBottomY = pos.dy + cardHeight / 2;

          // Only draw for children that are actually positioned
          final posKids = kids.where((k) => nodePositions.containsKey(k)).toList();
          if (posKids.isEmpty) continue;

          final childTopY = nodePositions[posKids.first]!.dy - cardHeight / 2;
          final bracketY = (parentBottomY + childTopY) / 2;

          // T-junction: vertical connector starts from spouse line (pos.dy)
          // so the line visually joins the horizontal spouse connector.
          // For single parents the hidden portion behind the card is harmless.
          final verticalStartY = pos.dy;

          // 1. Vertical drop from couple midpoint to bracket level
          lines.add(ConnectionLine(
            start: Offset(midX, verticalStartY),
            end: Offset(midX, bracketY),
            type: LineType.straight,
          ));

          if (posKids.length == 1) {
            final kidPos = nodePositions[posKids.first]!;
            if ((kidPos.dx - midX).abs() < 1) {
              // Child directly below — straight vertical
              lines.add(ConnectionLine(
                start: Offset(midX, bracketY),
                end: Offset(kidPos.dx, childTopY),
                type: LineType.straight,
              ));
            } else {
              // Child offset — horizontal jog then vertical
              lines.add(ConnectionLine(
                start: Offset(midX, bracketY),
                end: Offset(kidPos.dx, bracketY),
                type: LineType.straight,
              ));
              lines.add(ConnectionLine(
                start: Offset(kidPos.dx, bracketY),
                end: Offset(kidPos.dx, childTopY),
                type: LineType.straight,
              ));
            }
          } else {
            // 2. Horizontal bracket across all children
            double leftmostX = double.infinity;
            double rightmostX = double.negativeInfinity;
            for (final kid in posKids) {
              final kp = nodePositions[kid]!;
              if (kp.dx < leftmostX) leftmostX = kp.dx;
              if (kp.dx > rightmostX) rightmostX = kp.dx;
            }
            lines.add(ConnectionLine(
              start: Offset(leftmostX, bracketY),
              end: Offset(rightmostX, bracketY),
              type: LineType.straight,
            ));

            // 3. Vertical drop from bracket to each child
            for (final kid in posKids) {
              final kp = nodePositions[kid]!;
              lines.add(ConnectionLine(
                start: Offset(kp.dx, bracketY),
                end: Offset(kp.dx, childTopY),
                type: LineType.straight,
              ));
            }
          }
        }
      }
    }

    // Add buttons for missing relatives — for EVERY node, not just root
    final addButtons = <_AddButton>[];
    // Track which button types are already generated for a person to avoid duplicates
    final siblingButtonAdded = <String>{};
    final childButtonAdded = <String>{};
    
    for (final node in nodes) {
      final personId = node.person.id;
      final pos = nodePositions[personId];
      if (pos == null) continue;

      final parents = parentOf[personId] ?? [];
      final children = childrenOf[personId] ?? [];
      final hasSpouse = spouseOf[personId] != null;
      final spouseId = spouseOf[personId];
      
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
          y: pos.dy - cardHeight / 2 - cardHeight - vGap + 10,
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
              ? motherPos.dx - cardWidth - spouseGap - cardWidth / 2
              : pos.dx - cardWidth - hGap / 2;
          final fy = motherPos != null
              ? motherPos.dy - cardHeight / 2
              : pos.dy - cardHeight / 2 - cardHeight - vGap + 10;
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
              ? fatherPos.dx + cardWidth + spouseGap - cardWidth / 2
              : pos.dx + cardWidth + hGap / 2;
          final my = fatherPos != null
              ? fatherPos.dy - cardHeight / 2
              : pos.dy - cardHeight / 2 - cardHeight - vGap + 10;
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
      if (!hasSpouse) {
        addButtons.add(_AddButton(
          x: pos.dx + cardWidth / 2 + spouseGap,
          y: pos.dy - cardHeight / 2,
          label: 'Add Spouse',
          relativePersonId: personId,
          relationshipType: 'SPOUSE_OF',
        ));
      }

      // Sibling — show once per family group (avoid duplicate for both spouses)
      if (parents.isNotEmpty) {
        // Use a canonical key: sorted parent IDs to deduplicate siblings from same family
        final parentKey = (List<String>.from(parents)..sort()).join(',');
        if (!siblingButtonAdded.contains(parentKey)) {
          siblingButtonAdded.add(parentKey);
          
          // Find the rightmost card in this person's row (self + spouse if any)
          double rightEdge = pos.dx + cardWidth / 2;
          if (hasSpouse) {
            final spousePos = nodePositions[spouseId];
            if (spousePos != null) {
              final spouseRight = spousePos.dx + cardWidth / 2;
              if (spouseRight > rightEdge) rightEdge = spouseRight;
            }
          }
          addButtons.add(_AddButton(
            x: rightEdge + hGap,
            y: pos.dy - cardHeight / 2,
            label: 'Add Sibling',
            relativePersonId: personId,
            relationshipType: 'SIBLING_OF',
          ));
        }
      }

      // Child — show below, centered between couple; only once per couple
      if (children.isEmpty) {
        final childKey = hasSpouse
            ? ([personId, spouseId!]..sort()).join(',')
            : personId;
        if (!childButtonAdded.contains(childKey)) {
          childButtonAdded.add(childKey);
          double childX;
          if (hasSpouse) {
            final spousePos = nodePositions[spouseId];
            if (spousePos != null) {
              // Center between the two cards
              final coupleCenter = (pos.dx + spousePos.dx) / 2;
              childX = coupleCenter - addBtnWidth / 2;
            } else {
              childX = pos.dx - addBtnWidth / 2;
            }
          } else {
            childX = pos.dx - addBtnWidth / 2;
          }
          addButtons.add(_AddButton(
            x: childX,
            y: pos.dy + cardHeight / 2 + 20,
            label: 'Add Child',
            relativePersonId: personId,
            relationshipType: 'CHILD_OF',
          ));
        }
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

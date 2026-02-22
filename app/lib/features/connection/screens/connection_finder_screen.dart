import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/api_service.dart';

/// Screen where two people can enter each other's username and
/// discover the relationship path connecting them (if any).
class ConnectionFinderScreen extends ConsumerStatefulWidget {
  final String? targetUsername; // Pre-fill target username from query param

  const ConnectionFinderScreen({
    super.key,
    this.targetUsername,
  });

  @override
  ConsumerState<ConnectionFinderScreen> createState() =>
      _ConnectionFinderScreenState();
}

class _ConnectionFinderScreenState
    extends ConsumerState<ConnectionFinderScreen> {
  final _usernameAController = TextEditingController();
  final _usernameBController = TextEditingController();
  bool _isLoading = false;
  ConnectionResult? _result;
  String? _error;
  int _selectedPathIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill target username if provided
    if (widget.targetUsername != null) {
      _usernameBController.text = widget.targetUsername!;
    }
  }

  @override
  void dispose() {
    _usernameAController.dispose();
    _usernameBController.dispose();
    super.dispose();
  }

  Future<void> _findConnection() async {
    final usernameA = _usernameAController.text.trim();
    final usernameB = _usernameBController.text.trim();

    if (usernameA.isEmpty || usernameB.isEmpty) {
      setState(() => _error = 'Please enter both usernames');
      return;
    }

    if (usernameA == usernameB) {
      setState(() => _error = 'Cannot find connection with yourself');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.findConnectionByUsername(usernameA, usernameB);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _copyMyUsername() {
    final username = _usernameAController.text.trim();
    if (username.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: username));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your username copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Reverse/swap the usernames
  void _reverseSearch() {
    final temp = _usernameAController.text;
    _usernameAController.text = _usernameBController.text;
    _usernameBController.text = temp;
  }

  /// Share the connection result
  void _shareConnection() {
    if (_result == null ||!_result!.connected || _result!.paths.isEmpty) return;

    final pathData = _result!.paths[_selectedPathIndex];
    final calc = pathData.calculatedRelationship;
    
    final userA = pathData.path.first.name;
    final userB = pathData.path.last.name;
    final relationship = calc?.description ?? 'relative';
    
    String shareText = '🌳 Family Connection Found!\n\n';
    shareText += '$userB is $userA\'s $relationship.\n';
    shareText += 'Distance: ${pathData.depth} step${pathData.depth == 1 ? '' : 's'}\n';
    
    if (calc?.geneticSimilarity != null && calc!.geneticSimilarity! > 0) {
      shareText += 'Genetic similarity: ~${calc.geneticSimilarity!.toStringAsFixed(1)}%\n';
    }
    
    if (_result!.commonAncestors.isNotEmpty) {
      shareText += '\nCommon ancestor: ${_result!.commonAncestors.first.name}\n';
    }
    
    shareText += '\nPath:\n';
    for (int i = 0; i < pathData.path.length; i++) {
      shareText += '  ${i + 1}. ${pathData.path[i].name}';
      if (i < pathData.relationships.length) {
        shareText += ' → ${pathData.relationships[i].label}';
      }
      shareText += '\n';
    }

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.link_rounded, size: 22, color: kPrimaryColor),
            SizedBox(width: 8),
            Text('Connection Finder'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withValues(alpha: 0.5)),
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 700,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimaryColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: kPrimaryColor.withValues(alpha: 0.7), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share your username with someone, and enter theirs below to discover how you\'re connected through the family tree.',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Person A (Me)
            _buildLabel('Your Username'),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final profileAsync = ref.watch(myProfileProvider);
                
                // Auto-populate username when profile loads
                profileAsync.whenData((profile) {
                  if (profile != null && 
                      profile.username != null && 
                      _usernameAController.text.isEmpty) {
                    // Use addPostFrameCallback to avoid calling setState during build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _usernameAController.text = profile.username!;
                      }
                    });
                  }
                });

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameAController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: profileAsync.isLoading 
                              ? 'Loading your username...' 
                              : 'Your username',
                          prefixIcon: const Icon(Icons.alternate_email, size: 20),
                          filled: true,
                          fillColor: kSurfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kDividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kDividerColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _copyMyUsername,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.copy_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Share this username with the other person',
              style: TextStyle(color: kTextDisabled, fontSize: 11),
            ),
            const SizedBox(height: 24),

            // Connection icon between fields with reverse button
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kAccentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.swap_vert_rounded,
                        color: kAccentColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    elevation: 1,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: _reverseSearch,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kSurfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kDividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 18, color: kPrimaryColor),
                            const SizedBox(width: 6),
                            Text('Reverse', style: TextStyle(fontSize: 13, color: kPrimaryColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Person B (Other person)
            _buildLabel("Other Person's Username"),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setTextFieldState) => TextField(
                controller: _usernameBController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _findConnection(),
                onChanged: (_) => setTextFieldState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter their username',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  filled: true,
                  fillColor: kSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kDividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: kDividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_usernameBController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Clear',
                          onPressed: () {
                            _usernameBController.clear();
                            setTextFieldState(() {});
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 20),
                        tooltip: 'Paste from clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _usernameBController.text = data!.text!;
                            setTextFieldState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 32),

            // Find Connection button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _findConnection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? 'Searching...' : 'Find Connection',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kErrorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kErrorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kErrorColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: kErrorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Results
            if (_result != null) _buildResultCard(_result!),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
    );
  }

  Widget _buildResultCard(ConnectionResult result) {
    if (!result.connected) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kAccentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kAccentColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.link_off_rounded, size: 48, color: kAccentColor.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            const Text(
              'No Connection Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'These two people are not connected in the family tree. They may belong to different family trees.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      );
    }

    final currentPath = result.paths.isNotEmpty ? result.paths[_selectedPathIndex] : null;
    if (currentPath == null) return const SizedBox.shrink();

    final calc = currentPath.calculatedRelationship;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with calculated relationship
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded, color: kPrimaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (calc != null) ...[
                      Text(
                        calc.description.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Text(
                          '${currentPath.depth} step${currentPath.depth == 1 ? '' : 's'}',
                          style: TextStyle(color: kTextSecondary, fontSize: 12),
                        ),
                        if (calc?.isBloodRelation == true && calc?.geneticSimilarity != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kAccentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '~${calc!.geneticSimilarity!.toStringAsFixed(1)}% DNA',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kAccentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: _shareConnection,
                tooltip: 'Share connection',
                color: kPrimaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multiple paths selector
          if (result.paths.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(result.paths.length, (i) {
                final isSelected = i == _selectedPathIndex;
                return Material(
                  elevation: isSelected ? 2 : 0,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedPathIndex = i),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimaryColor : kSurfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : kDividerColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.route_rounded,
                            size: 14,
                            color: isSelected ? Colors.white : kTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Path ${i + 1} (${result.paths[i].depth} steps)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],

          // Common ancestors
          if (result.commonAncestors.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kAccentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kAccentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_tree_rounded, size: 18, color: kAccentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Common Ancestor',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.commonAncestors.first.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result.commonAncestors.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kAccentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${result.commonAncestors.length - 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kAccentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Connection path visualization
          ...List.generate(currentPath.path.length, (i) {
            final person = currentPath.path[i];
            final isFirst = i == 0;
            final isLast = i == currentPath.path.length - 1;
            final genderColor = person.gender == 'male'
                ? kMaleColor
                : person.gender == 'female'
                    ? kFemaleColor
                    : kTextSecondary;

            return Column(
              children: [
                // Person chip
                InkWell(
                  onTap: () => context.push('/person/${person.personId}'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isFirst || isLast)
                          ? genderColor.withValues(alpha: 0.12)
                          : kSurfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isFirst || isLast)
                            ? genderColor.withValues(alpha: 0.3)
                            : kDividerColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          person.gender == 'male'
                              ? Icons.person_rounded
                              : person.gender == 'female'
                                  ? Icons.person_2_rounded
                                  : Icons.person_outline_rounded,
                          color: genderColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          person.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: (isFirst || isLast)
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: kTextPrimary,
                          ),
                        ),
                        if (isFirst) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Relationship arrow
                if (i < currentPath.relationships.length) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_downward_rounded,
                            size: 16, color: kTextDisabled),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kSecondaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentPath.relationships[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

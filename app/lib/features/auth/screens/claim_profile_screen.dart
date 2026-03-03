import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../providers/providers.dart';
import '../../../config/theme.dart';

/// Screen shown after profile setup when the phone number matches an existing
/// person in someone else's family tree. Allows the user to claim that profile
/// and join the existing tree instead of creating a duplicate.
class ClaimProfileScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> matches;
  final Map<String, dynamic>? profileData;

  const ClaimProfileScreen({
    super.key,
    required this.matches,
    this.profileData,
  });

  @override
  ConsumerState<ClaimProfileScreen> createState() => _ClaimProfileScreenState();
}

class _ClaimProfileScreenState extends ConsumerState<ClaimProfileScreen> {
  bool _isClaiming = false;
  String? _error;

  Future<void> _claimProfile(Map<String, dynamic> match) async {
    final person = match['person'] as Map<String, dynamic>;
    final personId = person['id'] as String;

    setState(() { _isClaiming = true; _error = null; });

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.claimProfile(
        personId: personId,
        email: widget.profileData?['email'] as String?,
        profileUpdates: widget.profileData != null ? {
          if (widget.profileData!['username'] != null) 'username': widget.profileData!['username'],
          if (widget.profileData!['given_name'] != null) 'given_name': widget.profileData!['given_name'],
          if (widget.profileData!['surname'] != null) 'surname': widget.profileData!['surname'],
          if (widget.profileData!['date_of_birth'] != null) 'date_of_birth': widget.profileData!['date_of_birth'],
          if (widget.profileData!['occupation'] != null) 'occupation': widget.profileData!['occupation'],
          if (widget.profileData!['community'] != null) 'community': widget.profileData!['community'],
          if (widget.profileData!['gotra'] != null) 'gotra': widget.profileData!['gotra'],
          if (widget.profileData!['city'] != null) 'city': widget.profileData!['city'],
          if (widget.profileData!['state'] != null) 'state': widget.profileData!['state'],
        } : null,
      );

      // Refresh providers to load the claimed profile
      ref.invalidate(myProfileProvider);
      ref.invalidate(familyTreeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile claimed! Welcome to your family tree.'),
            backgroundColor: kSuccessColor,
          ),
        );
        context.go('/tree');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isClaiming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('We Found You!'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tree'),
          tooltip: 'Skip — Create new profile',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kPrimaryColor.withValues(alpha: 0.08),
                        kSecondaryLight.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kPrimaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.family_restroom_rounded, 
                        size: 56, color: kPrimaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'A family member already added you!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your phone number matches an existing profile in a family tree. '
                        'You can claim this profile to join that tree directly.',
                        style: TextStyle(color: kTextSecondary, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Match cards
                ...widget.matches.map((match) => _buildMatchCard(match)),

                const SizedBox(height: AppSpacing.lg),

                // Skip option
                OutlinedButton.icon(
                  onPressed: _isClaiming ? null : () => context.go('/tree'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('No, create a fresh profile instead'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: kTextSecondary.withValues(alpha: 0.3)),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kErrorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kErrorColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!, 
                      style: TextStyle(color: kErrorColor, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final person = match['person'] as Map<String, dynamic>;
    final addedBy = match['addedBy'] as String? ?? 'Someone';
    final relationshipCount = match['relationshipCount'] as int? ?? 0;

    final name = person['name'] as String? ?? 'Unknown';
    final gender = person['gender'] as String? ?? 'other';
    final city = person['city'] as String?;
    final state = person['state'] as String?;
    final dob = person['date_of_birth'] as String?;
    final photoUrl = person['photo_url'] as String?;

    final Color accentColor = gender == 'male' 
        ? kMaleColor 
        : gender == 'female' 
            ? kFemaleColor 
            : kOtherColor;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Person info row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                      ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(
                          gender == 'male' ? Icons.person : 
                          gender == 'female' ? Icons.person_2 : Icons.person_outline,
                          color: accentColor,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Name & details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (city != null || state != null)
                        Text(
                          [city, state].where((s) => s != null && s.isNotEmpty).join(', '),
                          style: TextStyle(color: kTextSecondary, fontSize: 13),
                        ),
                      if (dob != null)
                        Text('Born: $dob', 
                          style: TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Who added them
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kInfoColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, 
                    size: 16, color: kInfoColor),
                  const SizedBox(width: 6),
                  Text(
                    'Added by $addedBy',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: kInfoColor),
                  ),
                  if (relationshipCount > 0) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.people_outline, size: 16, color: kInfoColor),
                    const SizedBox(width: 4),
                    Text(
                      '$relationshipCount family ${relationshipCount == 1 ? "member" : "members"}',
                      style: TextStyle(fontSize: 13, color: kInfoColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Claim button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isClaiming ? null : () => _claimProfile(match),
                icon: _isClaiming 
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(_isClaiming ? 'Claiming...' : 'Yes, this is me — Claim this profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

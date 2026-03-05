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
  bool _isCheckingStatus = false;
  String? _error;

  // Pending-approval state — set when the backend returns status='pending'
  bool _isPending = false;
  String? _pendingPersonName;
  String? _pendingExpiresAt;

  Future<void> _claimProfile(Map<String, dynamic> match) async {
    final person = match['person'] as Map<String, dynamic>;
    final personId = person['id'] as String;

    setState(() { _isClaiming = true; _error = null; });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.claimProfile(
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

      // ── Pending: tree owner needs to approve first ──────────────────────
      if (response['status'] == 'pending') {
        setState(() {
          _isPending = true;
          _pendingPersonName = person['name'] as String? ?? 'the profile';
          _pendingExpiresAt = response['expires_at'] as String?;
          _isClaiming = false;
        });
        return;
      }

      // ── Approved (immediately or auto-approved after expiry) ────────────
      await _finishApprovedClaim(apiService, personId);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isClaiming = false;
      });
    }
  }

  /// Shared helper used both after immediate approval and after
  /// [_checkStatus] detects an auto-approved expired claim.
  Future<void> _finishApprovedClaim(
      ApiService apiService, String personId) async {
    // Give the backend a moment to propagate the auth_user_id link before
    // we start polling — the claim endpoint writes to the DB synchronously
    // but connection-pool / replica lag can cause getMyTree() to miss it.
    await Future.delayed(const Duration(milliseconds: 500));

    // Pre-warm the tree using the claimed person's ID directly (avoids any
    // auth_user_id lookup race condition on the first fetch after claim).
    try {
      await apiService.getTree(personId);
    } catch (_) {
      // Non-critical — continue; tree screen can still refetch on its own.
    }

    // Refresh myProfile first so hasProfileProvider returns true before
    // familyTreeProvider fires (prevents an extra empty-tree render).
    ref.invalidate(myProfileProvider);
    await ref.read(myProfileProvider.future).catchError((_) => null);

    // Now refresh the tree — myProfile is already settled so the backend
    // lookup by auth_user_id should succeed reliably.
    ref.invalidate(familyTreeProvider);
    await ref.read(familyTreeProvider.future).catchError((_) => null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile claimed! Welcome to your family tree.'),
          backgroundColor: kSuccessColor,
        ),
      );
      context.go('/tree');
    }
  }

  /// Called when the user taps "Check Status" on the pending-approval screen.
  Future<void> _checkStatus() async {
    setState(() { _isCheckingStatus = true; _error = null; });
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.getMyPendingClaim();

      if (data['autoApproved'] == true) {
        // The 7-day window passed — backend auto-approved the claim.
        final claimedPerson = data['person'] as Map<String, dynamic>?;
        final claimedId = claimedPerson?['id'] as String?;
        if (claimedId != null) {
          await _finishApprovedClaim(apiService, claimedId);
        } else {
          // Fallback: no person ID returned — just refresh and go
          ref.invalidate(myProfileProvider);
          await ref.read(myProfileProvider.future).catchError((_) => null);
          ref.invalidate(familyTreeProvider);
          if (mounted) context.go('/tree');
        }
      } else if (data['hasPendingClaim'] == false) {
        // Claim was rejected (or expired without auto-approve on the backend).
        setState(() {
          _isPending = false;
          _isCheckingStatus = false;
          _error = 'Your claim request was declined or expired. '  
              'You may create a fresh profile instead.';
        });
      } else {
        // Still pending — just re-show the pending screen.
        setState(() { _isCheckingStatus = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still waiting for the family member to approve…'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
        _error = e.toString().replaceAll('Exception: ', '');
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
          // Pop back to ProfileSetupScreen so the user can proceed with
          // creating a brand-new profile rather than jumping straight to /tree
          // (which would leave them with no profile record at all).
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/profile-setup');
            }
          },
          tooltip: 'Back — Create new profile instead',
        ),
      ),
      body: _isPending ? _buildPendingBody() : SingleChildScrollView(
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

                // Skip option — pop back so ProfileSetupScreen continues to
                // create a brand-new profile (rather than leaving the user
                // with no profile record at all).
                OutlinedButton.icon(
                  onPressed: _isClaiming ? null : () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/profile-setup');
                    }
                  },
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

  /// Full-screen body shown after the user submits a claim and it enters
  /// "pending approval" state, waiting for the tree owner to respond.
  Widget _buildPendingBody() {
    // Parse the ISO expiry string into a human-readable date if possible.
    String expiryText = 'within 7 days';
    if (_pendingExpiresAt != null) {
      try {
        final dt = DateTime.parse(_pendingExpiresAt!).toLocal();
        expiryText = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Illustration
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kWarningColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 52, color: kWarningColor),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Awaiting Approval',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your request to claim ${_pendingPersonName ?? 'this profile'} '
                'has been sent to the family member who created the tree.',
                style: TextStyle(fontSize: 15, color: kTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: kInfoColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kInfoColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.email_outlined, kInfoColor,
                        'An email has been sent to the tree owner for verification.'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.schedule_rounded, kInfoColor,
                        'If they don\'t respond by $expiryText, your claim will be auto-approved.'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.notifications_none_rounded, kInfoColor,
                        'You\'ll be notified once your request is approved or rejected.'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Check status button
              ElevatedButton.icon(
                onPressed: _isCheckingStatus ? null : _checkStatus,
                icon: _isCheckingStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(_isCheckingStatus
                    ? 'Checking\u2026'
                    : 'Check Approval Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Cancel / create fresh profile instead
              OutlinedButton.icon(
                onPressed: _isCheckingStatus
                    ? null
                    : () {
                        setState(() {
                          _isPending = false;
                          _pendingPersonName = null;
                          _pendingExpiresAt = null;
                        });
                      },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go back — choose a different match'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                      color: kTextSecondary.withValues(alpha: 0.35)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kErrorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: kErrorColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: TextStyle(color: kErrorColor, fontSize: 13)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: kTextSecondary)),
        ),
      ],
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

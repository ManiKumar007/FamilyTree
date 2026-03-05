import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

/// Shows a dialog prompting the user to complete their profile.
/// Returns `true` if the user has a profile (action can proceed),
/// `false` if they don't (action should be blocked).
///
/// Usage:
/// ```dart
/// onPressed: () async {
///   if (!await requireProfile(context, ref)) return;
///   // ... proceed with the write action
/// }
/// ```
Future<bool> requireProfile(BuildContext context, WidgetRef ref) async {
  final hasProfile = ref.read(hasProfileProvider);

  // Profile exists — allow the action
  if (hasProfile == true) return true;

  // Profile is still loading — wait briefly then check again
  if (hasProfile == null) {
    try {
      final profile = await ref.read(myProfileProvider.future);
      if (profile != null) return true;
    } catch (_) {
      // Fall through to show dialog
    }
  }

  // No profile — show the dialog
  if (!context.mounted) return false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(Icons.person_outline_rounded, size: 48, color: kWarningColor),
      title: const Text('Complete Your Profile'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You need to set up your profile before you can add family members, upload photos, or make other changes.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'It only takes a minute!',
            style: TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Not Now', style: TextStyle(color: kTextSecondary)),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(ctx).pop(true),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Set Up Profile'),
        ),
      ],
    ),
  );

  if (result == true && context.mounted) {
    context.push('/profile-setup');
  }

  return false;
}

/// A persistent banner shown at the top of screens when the user hasn't
/// completed their profile. Dismissible per session.
class ProfileCompletionBanner extends ConsumerWidget {
  const ProfileCompletionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(hasProfileProvider);
    final skipped = ref.watch(profileSkippedProvider);
    final dismissed = ref.watch(profileBannerDismissedProvider);

    // Only show if user is logged in, has no profile, skipped setup, and
    // hasn't dismissed the banner this session.
    if (hasProfile != false || !skipped || dismissed) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kWarningColor.withValues(alpha: 0.15),
              kAccentLight.withValues(alpha: 0.15),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: kWarningColor.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: kWarningColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete your profile to add family members and unlock all features.',
                style: TextStyle(fontSize: 13, color: kTextPrimary),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/profile-setup'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Complete', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                // Dismiss banner without touching profileSkippedProvider
                // (that flag is used by the router guard to allow navigation
                // without redirecting to /profile-setup).
                ref.read(profileBannerDismissedProvider.notifier).state = true;
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: kTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

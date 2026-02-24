import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

/// Enhanced empty state widget with optional Lottie animation
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset;
  final IconData? fallbackIcon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double? lottieSize;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.lottieAsset,
    this.fallbackIcon,
    this.actionLabel,
    this.onAction,
    this.lottieSize,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animation or icon
            if (lottieAsset != null)
              SizedBox(
                width: lottieSize ?? 200,
                height: lottieSize ?? 200,
                child: Lottie.asset(
                  lottieAsset!,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if Lottie fails
                    return Icon(
                      fallbackIcon ?? Icons.inbox_outlined,
                      size: 120,
                      color: kTextDisabled,
                    );
                  },
                ),
              )
            else
              Icon(
                fallbackIcon ?? Icons.inbox_outlined,
                size: 120,
                color: kTextDisabled,
              ),
            const SizedBox(height: AppSpacing.lg),
            // Title
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            // Message
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: kTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specific empty states for different scenarios
class NoDataEmpty extends StatelessWidget {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const NoDataEmpty({
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Data Available',
      message: message ?? 'There\'s nothing here yet. Start by adding some data.',
      lottieAsset: 'assets/lottie/empty_box.json',
      fallbackIcon: Icons.inbox_outlined,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Empty search results
class NoSearchResultsEmpty extends StatelessWidget {
  final String searchQuery;

  const NoSearchResultsEmpty({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Results Found',
      message: 'We couldn\'t find anything matching "$searchQuery". Try adjusting your search terms.',
      lottieAsset: 'assets/lottie/search_empty.json',
      fallbackIcon: Icons.search_off_outlined,
    );
  }
}

/// No family members yet
class NoFamilyMembersEmpty extends StatelessWidget {
  final VoidCallback? onAddMember;

  const NoFamilyMembersEmpty({
    super.key,
    this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Your Family Tree is Empty',
      message: 'Start building your family tree by adding your first family member.',
      lottieAsset: 'assets/lottie/family_tree.json',
      fallbackIcon: Icons.account_tree_outlined,
      actionLabel: 'Add Family Member',
      onAction: onAddMember,
    );
  }
}

/// No notifications
class NoNotificationsEmpty extends StatelessWidget {
  const NoNotificationsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Notifications',
      message: 'You\'re all caught up! We\'ll notify you when something new happens.',
      lottieAsset: 'assets/lottie/notifications_empty.json',
      fallbackIcon: Icons.notifications_none_outlined,
    );
  }
}

/// No pending merge requests
class NoPendingMergesEmpty extends StatelessWidget {
  const NoPendingMergesEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Pending Merges',
      message: 'There are no duplicate profiles to review at this time.',
      lottieAsset: 'assets/lottie/checklist.json',
      fallbackIcon: Icons.check_circle_outline,
    );
  }
}

/// Network error state
class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Connection Problem',
      message: 'We couldn\'t connect to the server. Please check your internet connection and try again.',
      lottieAsset: 'assets/lottie/network_error.json',
      fallbackIcon: Icons.wifi_off_outlined,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

/// Generic error state
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: title ?? 'Something Went Wrong',
      message: message ?? 'An unexpected error occurred. Please try again.',
      lottieAsset: 'assets/lottie/error.json',
      fallbackIcon: Icons.error_outline,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
    );
  }
}

/// Loading state with Lottie animation
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final double? size;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 150,
            height: size ?? 150,
            child: Lottie.asset(
              'assets/lottie/loading.json',
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator(
                  color: kPrimaryColor,
                );
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTextStyles.bodyLarge.copyWith(
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Success state with celebration animation
class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onContinue;
  final String? continueLabel;

  const SuccessStateWidget({
    super.key,
    required this.title,
    this.message,
    this.onContinue,
    this.continueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/lottie/success.json',
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.check_circle_outline,
                    size: 120,
                    color: kSuccessColor,
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: kTextSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onContinue != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccessColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                  ),
                ),
                child: Text(continueLabel ?? 'Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

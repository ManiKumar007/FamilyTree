import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../config/responsive.dart';
import 'shimmer_widgets.dart';

/// A beautiful avatar widget with gender-based colors and image support
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String gender;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.gender,
    this.name,
    this.size = AppSizing.avatarMd,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: getGenderColor(gender, light: true),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerAvatar(size: size),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              ),
            )
          : _buildPlaceholder(),
    );

    final Widget avatarWithSemantics = Semantics(
      label: name != null ? 'Profile picture of $name' : 'Profile picture',
      child: avatar,
    );

    final Widget content = showEditIcon
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatarWithSemantics,
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.camera_alt,
                    size: size / 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : avatarWithSemantics;

    return onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: content,
          )
        : content;
  }

  Widget _buildPlaceholder() {
    IconData icon;
    if (gender.toLowerCase() == 'male') {
      icon = Icons.person;
    } else if (gender.toLowerCase() == 'female') {
      icon = Icons.person_outline;
    } else {
      icon = Icons.person_outline;
    }

    return Icon(
      icon,
      size: size / 2,
      color: getGenderColor(gender),
    );
  }
}

/// A rich info card with icon, title, and subtitle
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: (iconColor ?? kPrimaryColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? kPrimaryColor,
                  size: AppSizing.iconLg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kTextSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: kTextSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A detail row for displaying label-value pairs
class DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;
  final Color? iconColor;

  const DetailRow({
    super.key,
    this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppSizing.iconSm,
              color: iconColor ?? kTextSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: kTextSecondary,
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A section header for organizing content
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onActionTap;
  final IconData? icon;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizing.iconSm, color: kPrimaryColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// A status badge for displaying information
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? kInfoColor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// An empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final emptyIconSize = r.value(mobile: 60.0, tablet: 72.0, desktop: 80.0);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: emptyIconSize,
              color: kTextDisabled,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kTextSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: kTextSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A relationship tag chip
class RelationshipChip extends StatelessWidget {
  final String relationshipType;
  final VoidCallback? onTap;

  const RelationshipChip({
    super.key,
    required this.relationshipType,
    this.onTap,
  });

  String get _displayLabel {
    final type = relationshipType.toUpperCase();
    if (type == 'FATHER_OF') return 'Father';
    if (type == 'MOTHER_OF') return 'Mother';
    if (type == 'CHILD_OF') return 'Child';
    if (type == 'SPOUSE_OF') return 'Spouse';
    if (type == 'SIBLING_OF') return 'Sibling';
    return relationshipType;
  }

  IconData get _icon {
    final type = relationshipType.toUpperCase();
    if (type.contains('FATHER') || type.contains('MOTHER')) return Icons.family_restroom;
    if (type.contains('CHILD')) return Icons.child_care;
    if (type.contains('SPOUSE')) return Icons.favorite;
    if (type.contains('SIBLING')) return Icons.groups;
    return Icons.link;
  }

  @override
  Widget build(BuildContext context) {
    final color = getRelationshipColor(relationshipType);
    return Chip(
      avatar: Icon(_icon, size: 16, color: color),
      label: Text(_displayLabel),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onDeleted: onTap,
      deleteIcon: onTap != null ? const Icon(Icons.close, size: 16) : null,
    );
  }
}

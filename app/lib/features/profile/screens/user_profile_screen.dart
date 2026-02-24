import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';
import '../../../widgets/common_widgets.dart';
import 'package:share_plus/share_plus.dart';

/// A comprehensive user profile screen with rich UI
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const EmptyState(
              icon: Icons.person_off,
              title: 'No Profile Found',
              subtitle: 'Please set up your profile to continue',
            );
          }
          return _buildProfileContent(profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Error Loading Profile',
          subtitle: error.toString(),
        ),
      ),
    );
  }

  Widget _buildProfileContent(Person profile) {
    return CustomScrollView(
      slivers: [
        // App Bar with profile header
        _buildAppBar(profile),

        // Profile content
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              
              // Quick Stats
              _buildQuickStats(profile),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Personal Information Section
              _buildPersonalInfoSection(profile),
              
              const SizedBox(height: AppSpacing.md),
              
              // Contact Information Section
              _buildContactInfoSection(profile),
              
              const SizedBox(height: AppSpacing.md),
              
              // Family Information Section
              _buildFamilyInfoSection(profile),
              
              const SizedBox(height: AppSpacing.md),
              
              // Actions Section
              _buildActionsSection(profile),
              
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Person profile) {
    final r = Responsive(context);
    return SliverAppBar(
      expandedHeight: r.appBarExpandedHeight,
      pinned: true,
      backgroundColor: kPrimaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => context.push('/edit-profile/${profile.id}'),
          tooltip: 'Edit Profile',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareProfile(profile),
          tooltip: 'Share Profile',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'More options',
          onSelected: (value) async {
            if (value == 'settings') {
              context.push('/account-settings');
            } else if (value == 'logout') {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: kAccentColor),
                  SizedBox(width: 12),
                  Text('Account Settings'),
                ],
              ),
            ),
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
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kPrimaryColor,
                kPrimaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Profile Picture
                Hero(
                  tag: 'profile-${profile.id}',
                  child: AppAvatar(
                    imageUrl: profile.photoUrl,
                    gender: profile.gender,
                    name: profile.name,
                    size: AppSizing.avatarXl,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Name
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Phone
                Text(
                  profile.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Verified Badge
                if (profile.verified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: kSuccessColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, color: Colors.white, size: 16),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Person profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.cake,
              label: 'Age',
              value: profile.age?.toString() ?? 'N/A',
              color: kAccentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: profile.gender == 'male' ? Icons.male : Icons.female,
              label: 'Gender',
              value: profile.gender.toUpperCase(),
              color: getGenderColor(profile.gender),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: 'Status',
              value: _formatMaritalStatus(profile.maritalStatus),
              color: kRelationshipSpouse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(Person profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Personal Information',
          icon: Icons.person,
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                if (profile.dateOfBirth != null)
                  DetailRow(
                    icon: Icons.cake,
                    label: 'Date of Birth',
                    value: _formatDate(profile.dateOfBirth!),
                    iconColor: kAccentColor,
                  ),
                if (profile.occupation != null)
                  DetailRow(
                    icon: Icons.work,
                    label: 'Occupation',
                    value: profile.occupation!,
                    iconColor: kPrimaryColor,
                  ),
                if (profile.community != null)
                  DetailRow(
                    icon: Icons.groups,
                    label: 'Community',
                    value: profile.community!,
                    iconColor: kSecondaryColor,
                  ),
                if (profile.gotra != null)
                  DetailRow(
                    icon: Icons.family_restroom,
                    label: 'Gotra',
                    value: profile.gotra!,
                    iconColor: kSecondaryColor,
                  ),
                DetailRow(
                  icon: Icons.wc,
                  label: 'Gender',
                  value: profile.gender.toUpperCase(),
                  iconColor: getGenderColor(profile.gender),
                ),
                DetailRow(
                  icon: Icons.favorite,
                  label: 'Marital Status',
                  value: _formatMaritalStatus(profile.maritalStatus),
                  iconColor: kRelationshipSpouse,
                ),
                if (profile.weddingDate != null)
                  DetailRow(
                    icon: Icons.celebration,
                    label: 'Wedding Date',
                    value: _formatDate(profile.weddingDate!),
                    iconColor: kRelationshipSpouse,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(Person profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Contact Information',
          icon: Icons.contact_phone,
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: profile.phone,
                  iconColor: kSuccessColor,
                ),
                if (profile.email != null)
                  DetailRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: profile.email!,
                    iconColor: kInfoColor,
                  ),
                if (profile.city != null)
                  DetailRow(
                    icon: Icons.location_city,
                    label: 'City',
                    value: profile.city!,
                    iconColor: kPrimaryColor,
                  ),
                if (profile.state != null)
                  DetailRow(
                    icon: Icons.map,
                    label: 'State',
                    value: profile.state!,
                    iconColor: kSecondaryColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyInfoSection(Person profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Family Tree',
          icon: Icons.account_tree,
          action: 'View Tree',
          onActionTap: () => context.go('/tree'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: InfoCard(
            icon: Icons.account_tree,
            title: 'View Full Family Tree',
            subtitle: 'Explore your family connections',
            iconColor: kPrimaryColor,
            onTap: () => context.go('/tree'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(Person profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Actions',
          icon: Icons.settings,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              InfoCard(
                icon: Icons.person_add,
                title: 'Add Family Member',
                subtitle: 'Add a new person to your family tree',
                iconColor: kSuccessColor,
                onTap: () => context.push('/tree/add-member'),
              ),
              InfoCard(
                icon: Icons.search,
                title: 'Search Network',
                subtitle: 'Find and connect with relatives',
                iconColor: kSecondaryColor,
                onTap: () => context.push('/search'),
              ),
              InfoCard(
                icon: Icons.merge_type,
                title: 'Pending Merges',
                subtitle: 'Review merge requests',
                iconColor: kWarningColor,
                onTap: () => context.go('/tree'), // Merges are shown in tree view
              ),
              InfoCard(
                icon: Icons.group_add,
                title: 'Invite Family',
                subtitle: 'Invite relatives to join',
                iconColor: kInfoColor,
                onTap: () => context.push('/invite'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMaritalStatus(String status) {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _shareProfile(Person profile) {
    Share.share(
      'Check out ${profile.name}\'s profile on MyFamilyTree!\nPhone: ${profile.phone}',
      subject: 'MyFamilyTree Profile',
    );
  }
}

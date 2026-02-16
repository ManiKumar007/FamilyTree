import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_layout.dart';

/// Flashy landing page showcasing all features
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return AppScaffold(
      showFooter: true,
      compactFooter: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            _buildHeroSection(isMobile),

            // Features Section
            _buildFeaturesSection(isMobile),

            // How It Works Section
            _buildHowItWorksSection(isMobile),

            // CTA Section
            _buildCTASection(isMobile),
          ],
        ),
      ),
    );
  }

  /// Hero section with main headline and CTA
  Widget _buildHeroSection(bool isMobile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
            vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Tree Icon with glow effect
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_tree,
                      size: isMobile ? 60 : 80,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // Main headline
                  Text(
                    'Connect Your Family Tree',
                    style: TextStyle(
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Subheadline
                  Text(
                    'Discover, Connect, and Preserve Your Family Legacy',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // CTA Buttons
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Get Started'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            vertical: AppSpacing.md,
                          ),
                          textStyle: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 8,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.preview),
                        label: const Text('Sign Up Free'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                            vertical: AppSpacing.md,
                          ),
                          textStyle: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Features section with icons and descriptions
  Widget _buildFeaturesSection(bool isMobile) {
    return Container(
      color: kBackgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // Section Title
          Text(
            'Powerful Features for Indian Families',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Everything you need to build and connect your family tree',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),

          // Feature Cards
          _buildFeatureGrid(isMobile),
        ],
      ),
    );
  }

  /// Grid of feature cards
  Widget _buildFeatureGrid(bool isMobile) {
    final features = [
      _FeatureData(
        icon: Icons.account_tree,
        iconColor: kPrimaryColor,
        title: 'Interactive Family Tree',
        description:
            'Geni-style pannable and zoomable canvas with color-coded gender cards for beautiful visualization',
      ),
      _FeatureData(
        icon: Icons.phone_android,
        iconColor: kSecondaryColor,
        title: 'Smart Auto-Merge',
        description:
            'Automatically detect and merge duplicate profiles using phone numbers across different family trees',
      ),
      _FeatureData(
        icon: Icons.search,
        iconColor: kAccentColor,
        title: 'N-Circle Network Search',
        description:
            'Discover relatives and potential matches within 1-10 relationship hops in your extended network',
      ),
      _FeatureData(
        icon: Icons.message,
        iconColor: kSuccessColor,
        title: 'WhatsApp Invites',
        description:
            'Generate shareable invite links to add family members who can claim and manage their profiles',
      ),
      _FeatureData(
        icon: Icons.verified_user,
        iconColor: kSecondaryColor,
        title: 'Google & Email Auth',
        description:
            'Secure authentication via Google Sign-In or passwordless magic link emails using Supabase',
      ),
      _FeatureData(
        icon: Icons.compare_arrows,
        iconColor: kWarningColor,
        title: 'Smart Conflict Resolution',
        description:
            'Review and approve merge requests with side-by-side profile comparison for data accuracy',
      ),
      _FeatureData(
        icon: Icons.person,
        iconColor: kInfoColor,
        title: 'Rich Indian Profiles',
        description:
            'Complete profiles with community, occupation, city, marital status, and more Indian-specific fields',
      ),
      _FeatureData(
        icon: Icons.security,
        iconColor: kPrimaryDark,
        title: 'Privacy & Security',
        description:
            'Row-level security with Supabase ensuring your family data is protected and private',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 1 : (constraints.maxWidth > 900 ? 3 : 2);
        final childAspectRatio = isMobile ? 1.3 : 1.1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppSpacing.lg,
            mainAxisSpacing: AppSpacing.lg,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _FeatureCard(feature: features[index]);
          },
        );
      },
    );
  }

  /// How it works section
  Widget _buildHowItWorksSection(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // Section Title
          Text(
            'How It Works',
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),

          // Steps
          _buildStepsList(isMobile),
        ],
      ),
    );
  }

  /// List of steps
  Widget _buildStepsList(bool isMobile) {
    final steps = [
      _StepData(
        number: '1',
        title: 'Sign Up',
        description:
            'Create your account using Google Sign-In or email magic link for quick and secure access.',
        icon: Icons.login,
      ),
      _StepData(
        number: '2',
        title: 'Build Your Tree',
        description:
            'Add family members with rich profile details including photos, relationships, and Indian-specific fields.',
        icon: Icons.add_circle,
      ),
      _StepData(
        number: '3',
        title: 'Invite Family',
        description:
            'Share WhatsApp invite links with relatives so they can claim their profiles and contribute to the tree.',
        icon: Icons.share,
      ),
      _StepData(
        number: '4',
        title: 'Discover Connections',
        description:
            'Use network search to find distant relatives and automatically merge trees when phone numbers match.',
        icon: Icons.connect_without_contact,
      ),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final isLast = entry.key == steps.length - 1;
        return _StepItem(
          step: entry.value,
          isMobile: isMobile,
          showConnector: !isLast,
        );
      }).toList(),
    );
  }

  /// Final CTA section
  Widget _buildCTASection(bool isMobile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: isMobile ? 60 : 80,
            color: Colors.white,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Start Building Your Family Legacy Today',
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Join thousands of families preserving their heritage',
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),
          ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Get Started Free'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.xl : AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              textStyle: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature data model
class _FeatureData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  _FeatureData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

/// Feature card widget
class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;

  const _FeatureCard({required this.feature});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        child: Card(
          elevation: _isHovered ? 12 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.borderRadiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: widget.feature.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.feature.icon,
                    size: 40,
                    color: widget.feature.iconColor,
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // Title
                Text(
                  widget.feature.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),

                // Description
                Text(
                  widget.feature.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Step data model
class _StepData {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  _StepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}

/// Step item widget
class _StepItem extends StatelessWidget {
  final _StepData step;
  final bool isMobile;
  final bool showConnector;

  const _StepItem({
    required this.step,
    required this.isMobile,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Number Circle
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [kPrimaryColor, kPrimaryLight],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      step.number,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (showConnector)
                  Container(
                    width: 2,
                    height: 80,
                    color: kDividerColor,
                  ),
              ],
            ),
            SizedBox(width: AppSpacing.lg),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: kPrimaryColor, size: 24),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: kTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showConnector) SizedBox(height: 0),
      ],
    );
  }
}

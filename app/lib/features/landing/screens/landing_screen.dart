import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../widgets/app_layout.dart';
import '../../../services/whatsapp_share_service.dart';

/// Rich, visually appealing landing page with depth and polish
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    ));

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return AppScaffold(
      showFooter: true,
      compactFooter: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(isMobile, isTablet, size),
            _buildFeaturesSection(isMobile),
            _buildHowItWorksSection(isMobile),
            _buildStatsSection(isMobile),
            _buildCTASection(isMobile),
          ],
        ),
      ),
    );
  }

  // ─── Hero Section ────────────────────────────────────────────
  Widget _buildHeroSection(bool isMobile, bool isTablet, Size size) {
    final heroHeight = isMobile ? size.height * 0.85 : size.height * 0.9;

    return SizedBox(
      height: heroHeight.clamp(500.0, 900.0),
      child: Stack(
        children: [
          // Base gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.heroRich),
            ),
          ),

          // Decorative tree-like pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _TreePatternPainter()),
          ),

          // Radial glow behind content
          Positioned(
            top: isMobile ? 80 : 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: isMobile ? 300 : 500,
                height: isMobile ? 300 : 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kPrimaryLight.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating orbs
          ..._buildFloatingOrbs(isMobile),

          // Main content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated tree icon with concentric rings
                        AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: _buildHeroIcon(isMobile),
                        ),
                        SizedBox(
                            height: isMobile ? AppSpacing.lg : AppSpacing.xl),

                        // Headline with gradient shimmer
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFB7E4C7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isMobile ? 36 : (isTablet ? 48 : 60),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1.5,
                              ),
                              children: [
                                const TextSpan(text: 'Your '),
                                TextSpan(
                                  text: 'Vansh',
                                  style: TextStyle(
                                    fontSize: isMobile ? 42 : (isTablet ? 56 : 70),
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFFFD700), // Gold color
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const TextSpan(text: ',\nYour Legacy'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        
                        // Hindi subtitle
                        Text(
                          'अपने वंश की विरासत को सुरक्षित रखें',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 20,
                            color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Emotional subheadline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: kAccentColor.withValues(alpha: 0.8),
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Your dadi\'s stories. Your nani\'s recipes. Your family\'s legacy.\nDon\'t let them fade away.',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 18,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.6,
                              fontWeight: FontWeight.w300,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        SizedBox(
                            height:
                                isMobile ? AppSpacing.xl : AppSpacing.xxl),

                        // CTA Buttons with glow
                        _buildHeroCTAs(isMobile),
                        SizedBox(height: AppSpacing.xl),

                        // Trust badges
                        _buildTrustBadges(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom wave transition
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(size.width, 80),
              painter: _WavePainter(color: const Color(0xFFF0F7F4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(bool isMobile) {
    final iconSize = isMobile ? 64.0 : 80.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: iconSize * 2.4,
          height: iconSize * 2.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        // Middle ring
        Container(
          width: iconSize * 1.8,
          height: iconSize * 1.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        // Inner glowing circle
        Container(
          width: iconSize * 1.3,
          height: iconSize * 1.3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.2),
                kPrimaryLight.withValues(alpha: 0.15),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryLight.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Icon(Icons.account_tree_rounded, size: iconSize, color: Colors.white),
      ],
    );
  }

  List<Widget> _buildFloatingOrbs(bool isMobile) {
    return [
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, _) {
          return Positioned(
            top: 60 + _floatAnimation.value * 0.5,
            left: isMobile ? -30 : 60,
            child: _buildOrb(80, kPrimaryLight.withValues(alpha: 0.06)),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, _) {
          return Positioned(
            top: 120 - _floatAnimation.value * 0.7,
            right: isMobile ? -20 : 80,
            child: _buildOrb(60, kAccentColor.withValues(alpha: 0.05)),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, _) {
          return Positioned(
            bottom: 140 + _floatAnimation.value * 0.4,
            left: isMobile ? 20 : 120,
            child: _buildOrb(50, kSecondaryLight.withValues(alpha: 0.06)),
          );
        },
      ),
    ];
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _buildHeroCTAs(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            // Primary CTA with glow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: kAccentColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.rocket_launch, size: 20),
                label: const Text('Get Started'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppSpacing.xl : AppSpacing.xxl,
                    vertical: AppSpacing.md + 4,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                  ),
                ),
              ),
            ),
            // Secondary CTA - glassmorphism style
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: TextButton.icon(
                onPressed: () => context.go('/signup'),
                icon: const Icon(Icons.person_add, size: 20),
                label: const Text('Sign Up Free'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? AppSpacing.xl : AppSpacing.xxl,
                    vertical: AppSpacing.md + 4,
                  ),
                  textStyle: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // WhatsApp share button
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            final message = WhatsAppShareService.generateInviteMessage(
              inviterName: 'a friend',
              recipientName: 'your family',
            );
            WhatsAppShareService.shareMilestone(message);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💚',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                'Share on WhatsApp',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.5),
                  decorationThickness: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadges(bool isMobile) {
    return Column(
      children: [
        // Social proof stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatBadge('12,847', 'Families', isMobile),
            SizedBox(width: isMobile ? 12 : 24),
            _buildStatBadge('247K+', 'Members', isMobile),
            SizedBox(width: isMobile ? 12 : 24),
            _buildStatBadge('8', 'Generations', isMobile),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        
        // Founding Families offer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withValues(alpha: 0.2),
                const Color(0xFFFF6B35).withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '👑',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Founding Families',
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LIMITED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'First 1,000 get Lifetime Premium • ${847} spots left',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        
        // Original trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ('🔒', 'Secure & Private'),
            ('🇮🇳', 'Made for India'),
            ('⚡', '100% Free'),
          ].map((badge) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(badge.$1, style: TextStyle(fontSize: isMobile ? 12 : 14)),
                  const SizedBox(width: 4),
                  Text(
                    badge.$2,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: isMobile ? 11 : 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String value, String label, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD700),
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 11 : 13,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Features Section ────────────────────────────────────────
  Widget _buildFeaturesSection(bool isMobile) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.featuresBg),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl * 1.5,
      ),
      child: Column(
        children: [
          // Section badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '✨ FEATURES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),

          Text(
            'Built for Your Vansh',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Made with love for Indian families. No complex settings, just pure connection.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: kTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),
          _buildFeatureGrid(isMobile),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(bool isMobile) {
    final features = [
      _FeatureData(
        icon: Icons.account_tree,
        gradient: const LinearGradient(
            colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
        title: 'Interactive Family Tree',
        description:
            'Geni-style pannable and zoomable canvas with color-coded gender cards',
      ),
      _FeatureData(
        icon: Icons.auto_fix_high,
        gradient: const LinearGradient(
            colors: [Color(0xFF3D5A80), Color(0xFF98C1D9)]),
        title: 'Smart Auto-Merge',
        description:
            'Automatically detect and merge duplicate profiles across trees',
      ),
      _FeatureData(
        icon: Icons.hub,
        gradient: const LinearGradient(
            colors: [Color(0xFFE76F51), Color(0xFFF4A261)]),
        title: 'N-Circle Network Search',
        description:
            'Discover relatives within 1-10 relationship hops in your network',
      ),
      _FeatureData(
        icon: Icons.send_rounded,
        gradient: const LinearGradient(
            colors: [Color(0xFF40C057), Color(0xFF69DB7C)]),
        title: 'WhatsApp Invites',
        description:
            'Generate shareable invite links to add family members easily',
      ),
      _FeatureData(
        icon: Icons.shield_rounded,
        gradient: const LinearGradient(
            colors: [Color(0xFF5C7CFA), Color(0xFF91A7FF)]),
        title: 'Google & Email Auth',
        description:
            'Secure authentication via Google Sign-In or magic link emails',
      ),
      _FeatureData(
        icon: Icons.compare_arrows_rounded,
        gradient: const LinearGradient(
            colors: [Color(0xFFFFB020), Color(0xFFFFD43B)]),
        title: 'Conflict Resolution',
        description:
            'Side-by-side profile comparison for accurate data merging',
      ),
      _FeatureData(
        icon: Icons.person_pin_rounded,
        gradient: const LinearGradient(
            colors: [Color(0xFF9775FA), Color(0xFFB197FC)]),
        title: 'Rich Indian Profiles',
        description:
            'Community, occupation, city, marital status & more Indian fields',
      ),
      _FeatureData(
        icon: Icons.lock_rounded,
        gradient: const LinearGradient(
            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
        title: 'Privacy & Security',
        description:
            'Row-level security ensuring your family data stays protected',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            isMobile ? 1 : (constraints.maxWidth > 900 ? 4 : 2);
        final childAspectRatio = isMobile ? 3.0 : 1.05;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            return _FeatureCard(feature: features[index]);
          },
        );
      },
    );
  }

  // ─── How It Works ────────────────────────────────────────────
  Widget _buildHowItWorksSection(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
        vertical: isMobile ? AppSpacing.xxl : AppSpacing.xxl * 1.5,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kSecondaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kSecondaryColor.withValues(alpha: 0.2)),
            ),
            child: const Text(
              '🚀 HOW IT WORKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kSecondaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Start Your Vansh Journey',
            style: TextStyle(
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xxl),
          _buildStepsList(isMobile),
        ],
      ),
    );
  }

  Widget _buildStepsList(bool isMobile) {
    final steps = [
      _StepData(
        number: '1',
        title: 'Create Account',
        description:
            'Sign up with Google or email magic link — no passwords needed.',
        icon: Icons.login_rounded,
        color: kPrimaryColor,
      ),
      _StepData(
        number: '2',
        title: 'Build Your Tree',
        description:
            'Add family members with rich Indian-specific profile details.',
        icon: Icons.add_circle_rounded,
        color: kAccentColor,
      ),
      _StepData(
        number: '3',
        title: 'Invite Family',
        description:
            'Share WhatsApp invite links so relatives can claim their profiles.',
        icon: Icons.share_rounded,
        color: kSuccessColor,
      ),
      _StepData(
        number: '4',
        title: 'Discover Connections',
        description:
            'Find distant relatives and auto-merge trees using phone matches.',
        icon: Icons.connect_without_contact_rounded,
        color: kSecondaryColor,
      ),
    ];

    if (isMobile) {
      return Column(
        children: steps.asMap().entries.map((entry) {
          final isLast = entry.key == steps.length - 1;
          return _StepItem(
            step: entry.value,
            isMobile: true,
            showConnector: !isLast,
          );
        }).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        return Expanded(
          child: _StepCardDesktop(step: entry.value, index: entry.key),
        );
      }).toList(),
    );
  }

  // ─── Stats Section ───────────────────────────────────────────
  Widget _buildStatsSection(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryDark.withValues(alpha: 0.95),
            kPrimaryColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle dot grid pattern
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
              vertical: AppSpacing.xxl,
            ),
            child: isMobile
                ? Column(
                    children: [
                      _buildStatItem(
                          '247K+', 'Stories Preserved', Icons.auto_stories_rounded),
                      SizedBox(height: AppSpacing.lg),
                      _buildStatItem(
                          '12,847', 'Families Reunited', Icons.diversity_3_rounded),
                      SizedBox(height: AppSpacing.lg),
                      _buildStatItem('8', 'Generations Discovered',
                          Icons.history_edu_rounded),
                      SizedBox(height: AppSpacing.lg),
                      _buildStatItem(
                          '127', 'Cities Across India', Icons.location_city_rounded),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                          '247K+', 'Stories Preserved', Icons.auto_stories_rounded),
                      _buildStatDivider(),
                      _buildStatItem(
                          '12,847', 'Families Reunited', Icons.diversity_3_rounded),
                      _buildStatDivider(),
                      _buildStatItem('8', 'Generations Discovered',
                          Icons.history_edu_rounded),
                      _buildStatDivider(),
                      _buildStatItem(
                          '127', 'Cities Across India', Icons.location_city_rounded),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: kPrimaryLight.withValues(alpha: 0.6)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 60,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  // ─── CTA Section ─────────────────────────────────────────────
  Widget _buildCTASection(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppGradients.hero),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.lg : AppSpacing.xxl,
              vertical: isMobile ? AppSpacing.xxl * 1.2 : AppSpacing.xxl * 1.5,
            ),
            child: Column(
              children: [
              // Decorative icon cluster
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: isMobile ? 100 : 130,
                    height: isMobile ? 100 : 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  Container(
                    width: isMobile ? 70 : 90,
                    height: isMobile ? 70 : 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.family_restroom,
                      size: isMobile ? 36 : 44,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              Text(
                'Your Vansh Awaits',
                style: TextStyle(
                  fontSize: isMobile ? 28 : 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                'Don\'t let your stories fade. Start preserving your family legacy in 2 minutes.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),

              // CTA button with glow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizing.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: kAccentColor.withValues(alpha: 0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Get Started Free'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isMobile ? AppSpacing.xl : AppSpacing.xxl * 1.2,
                      vertical: AppSpacing.lg,
                    ),
                    textStyle: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w700,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizing.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Top wave separator
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 50),
            painter: _WavePainter(
              color: kPrimaryDark.withValues(alpha: 0.95),
              flipVertically: true,
            ),
          ),
        ),
      ],
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Custom Painters
// ═══════════════════════════════════════════════════════════════

/// Faint tree branch/connection pattern behind the hero
class _TreePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final random = math.Random(42); // fixed seed for consistency

    // Draw tree-like branching lines
    for (int i = 0; i < 12; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height * 0.6;
      final path = Path();
      path.moveTo(startX, startY);

      final midX = startX + (random.nextDouble() - 0.5) * 120;
      final midY = startY + 60 + random.nextDouble() * 80;
      path.quadraticBezierTo(
        startX + (random.nextDouble() - 0.5) * 40,
        startY + 30,
        midX,
        midY,
      );

      // Sub-branch left
      final leftPath = Path();
      leftPath.moveTo(midX, midY);
      leftPath.quadraticBezierTo(
        midX - 30,
        midY + 15,
        midX - 40 - random.nextDouble() * 30,
        midY + 30 + random.nextDouble() * 20,
      );

      // Sub-branch right
      final rightPath = Path();
      rightPath.moveTo(midX, midY);
      rightPath.quadraticBezierTo(
        midX + 30,
        midY + 15,
        midX + 40 + random.nextDouble() * 30,
        midY + 30 + random.nextDouble() * 20,
      );

      canvas.drawPath(path, paint);
      canvas.drawPath(leftPath, paint);
      canvas.drawPath(rightPath, paint);

      // Connection nodes
      canvas.drawCircle(
        Offset(midX, midY),
        3,
        Paint()..color = Colors.white.withValues(alpha: 0.06),
      );
    }

    // Subtle circles representing family members
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int i = 0; i < 8; i++) {
      final cx = random.nextDouble() * size.width;
      final cy = random.nextDouble() * size.height;
      final r = 15.0 + random.nextDouble() * 25;
      canvas.drawCircle(Offset(cx, cy), r, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Smooth wave separator between sections
class _WavePainter extends CustomPainter {
  final Color color;
  final bool flipVertically;

  _WavePainter({required this.color, this.flipVertically = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (flipVertically) {
      path.moveTo(0, size.height);
      path.lineTo(0, size.height * 0.3);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.6,
        size.width * 0.5,
        size.height * 0.35,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.1,
        size.width,
        size.height * 0.4,
      );
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, size.height);
      path.lineTo(0, size.height * 0.6);
      path.quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.55,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.8,
        size.width,
        size.height * 0.5,
      );
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle dot grid pattern for stats section
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const radius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// Data Models
// ═══════════════════════════════════════════════════════════════

class _FeatureData {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String description;

  _FeatureData({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.description,
  });
}

class _StepData {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _StepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════
// Feature Card with gradient icon & hover animation
// ═══════════════════════════════════════════════════════════════

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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizing.borderRadiusLg),
          border: Border.all(
            color: _isHovered
                ? widget.feature.gradient.colors.first.withValues(alpha: 0.3)
                : kDividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.feature.gradient.colors.first.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 20 : 8,
              offset: Offset(0, _isHovered ? 8 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated gradient icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _isHovered ? widget.feature.gradient : null,
                  color: _isHovered
                      ? null
                      : widget.feature.gradient.colors.first.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.feature.icon,
                  size: 28,
                  color: _isHovered
                      ? Colors.white
                      : widget.feature.gradient.colors.first,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                widget.feature.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.xs),
              Flexible(
                child: Text(
                  widget.feature.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Step Widgets
// ═══════════════════════════════════════════════════════════════

/// Mobile step with connector line
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
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [step.color, step.color.withValues(alpha: 0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: step.color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      step.number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (showConnector)
                  Container(
                    width: 2,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [step.color.withValues(alpha: 0.3), kDividerColor],
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, color: step.color, size: 22),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 14,
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
      ],
    );
  }
}

/// Desktop step card with number + icon
class _StepCardDesktop extends StatelessWidget {
  final _StepData step;
  final int index;

  const _StepCardDesktop({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          // Step number circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [step.color, step.color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: step.color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                step.number,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(step.icon, color: step.color, size: 24),
          ),
          SizedBox(height: AppSpacing.md),

          Text(
            step.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              step.description,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

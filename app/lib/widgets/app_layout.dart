import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

/// Consistent app header with full navigation bar
class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: 0,
          backgroundColor: kSurfaceColor,
          foregroundColor: kTextPrimary,
          automaticallyImplyLeading: false,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
          title: title != null
              ? Text(
                  title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: kTextPrimary,
                  ),
                )
              : Row(
                  children: [
                    // Logo
                    InkWell(
                      onTap: () => context.go('/landing'),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.account_tree_rounded,
                                size: 20, color: kPrimaryColor),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            'MyFamilyTree',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: kTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Desktop nav links
                    if (!isMobile) ...[
                      const SizedBox(width: AppSpacing.xl),
                      _NavLink(
                        label: 'Family Tree',
                        icon: Icons.account_tree_outlined,
                        isActive: currentPath.startsWith('/tree'),
                        onTap: () => context.go('/tree'),
                      ),
                      _NavLink(
                        label: 'Blog',
                        icon: Icons.article_outlined,
                        isActive: currentPath.startsWith('/blog'),
                        onTap: () {
                          // TODO: Navigate to blog
                        },
                      ),
                      _NavLink(
                        label: 'Family Forum',
                        icon: Icons.forum_outlined,
                        isActive: currentPath.startsWith('/forum'),
                        onTap: () {
                          // TODO: Navigate to forum
                        },
                      ),
                    ],
                  ],
                ),
          actions: actions ??
              [
                // Desktop: inline auth buttons
                if (!isMobile) ...[
                  if (isLoggedIn) ...[
                    _NavLink(
                      label: 'Search',
                      icon: Icons.search_rounded,
                      isActive: currentPath.startsWith('/search'),
                      onTap: () => context.go('/search'),
                    ),
                    _NavLink(
                      label: 'Invite',
                      icon: Icons.person_add_outlined,
                      isActive: currentPath.startsWith('/invite'),
                      onTap: () => context.go('/invite'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // User menu
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: kPrimaryColor,
                              child: Text(
                                (authService.currentUser?.email ?? 'U')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: kTextSecondary),
                          ],
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) context.go('/login');
                        } else if (value == 'profile') {
                          context.go('/edit-profile/${authService.currentUser?.id}');
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authService.currentUser?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: kTextSecondary,
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  color: kTextSecondary, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('My Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: kErrorColor, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('Sign Out'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else ...[
                    // Not logged in — show Login & Sign Up
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: kTextPrimary,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                ],

                // Mobile: hamburger menu
                if (isMobile)
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded),
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  ),
              ],
        ),
        Container(height: 1, color: kDividerColor.withOpacity(0.5)),
      ],
    );
  }
}

/// A single navigation link for the top bar
class _NavLink extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    this.icon,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? kPrimaryColor.withOpacity(0.08)
                : (_isHovered ? kPrimaryColor.withOpacity(0.04) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isActive ? kPrimaryColor : kTextSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isActive ? kPrimaryColor : kTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile navigation drawer with all links
class AppNavDrawer extends ConsumerWidget {
  const AppNavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    final isLoggedIn = authService.isLoggedIn;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_tree_rounded,
                            size: 24, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'MyFamilyTree',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      authService.currentUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    isActive: currentPath == '/landing',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/landing');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.account_tree_outlined,
                    label: 'Family Tree',
                    isActive: currentPath.startsWith('/tree'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/tree');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.article_outlined,
                    label: 'Blog',
                    isActive: currentPath.startsWith('/blog'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to blog
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.forum_outlined,
                    label: 'Family Forum',
                    isActive: currentPath.startsWith('/forum'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to forum
                    },
                  ),
                  if (isLoggedIn) ...[
                    const Divider(),
                    _DrawerItem(
                      icon: Icons.search_rounded,
                      label: 'Search',
                      isActive: currentPath.startsWith('/search'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/search');
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.person_add_outlined,
                      label: 'Invite',
                      isActive: currentPath.startsWith('/invite'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/invite');
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Bottom auth section
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: kDividerColor),
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isLoggedIn
                  ? TextButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: kErrorColor, size: 20),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                            color: kErrorColor, fontWeight: FontWeight.w600),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/login');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: const BorderSide(color: kPrimaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Log In'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/signup');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Sign Up'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drawer navigation item
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? kPrimaryColor : kTextSecondary,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? kPrimaryColor : kTextPrimary,
          fontSize: 15,
        ),
      ),
      selected: isActive,
      selectedTileColor: kPrimaryColor.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }
}

/// Consistent app footer with links and info
class AppFooter extends StatelessWidget {
  final bool compact;

  const AppFooter({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: kSidebarBg,
          border: Border(
            top: BorderSide(color: kDividerColor, width: 1),
          ),
        ),
        child: const Center(
          child: Text(
            '\u00A9 2026 MyFamilyTree. Built with \u2764\uFE0F',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.sidebar,
        border: Border(
          top: BorderSide(color: kDividerColor, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Footer links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _FooterLink(
                label: 'About',
                onTap: () => context.go('/landing'),
              ),
              _FooterLink(
                label: 'Features',
                onTap: () => context.go('/landing'),
              ),
              _FooterLink(
                label: 'Privacy Policy',
                onTap: () {
                  // TODO: Navigate to privacy policy
                },
              ),
              _FooterLink(
                label: 'Terms of Service',
                onTap: () {
                  // TODO: Navigate to terms
                },
              ),
              _FooterLink(
                label: 'Contact',
                onTap: () {
                  // TODO: Navigate to contact
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Social media icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.white70),
                onPressed: () {
                  // TODO: Open Facebook
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.white70),
                onPressed: () {
                  // TODO: Open WhatsApp
                },
              ),
              IconButton(
                icon: const Icon(Icons.email, color: Colors.white70),
                onPressed: () {
                  // TODO: Open email
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Copyright
          Text(
            '© 2026 MyFamilyTree. All rights reserved.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Built with Flutter & Supabase',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Footer link widget
class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Scaffold wrapper with consistent header and footer
class AppScaffold extends StatelessWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget body;
  final bool showFooter;
  final bool compactFooter;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffold({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
    required this.body,
    this.showFooter = false,
    this.compactFooter = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppHeader(
        title: title,
        showBackButton: showBackButton,
        actions: actions,
      ),
      endDrawer: isMobile ? const AppNavDrawer() : null,
      body: Column(
        children: [
          Expanded(child: body),
          if (showFooter) AppFooter(compact: compactFooter),
        ],
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

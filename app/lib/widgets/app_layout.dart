import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';

/// Consistent app header with navigation
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          elevation: 0,
          backgroundColor: kSurfaceColor,
          foregroundColor: kTextPrimary,
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.account_tree_rounded, size: 20, color: kPrimaryColor),
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
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                )
              : null,
          actions: actions ??
              [
                IconButton(
                  icon: const Icon(Icons.account_tree_outlined, size: 20),
                  tooltip: 'View Family Tree',
                  onPressed: () => context.go('/tree'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
              onSelected: (value) async {
                switch (value) {
                  case 'tree':
                    context.go('/tree');
                    break;
                  case 'search':
                    context.go('/search');
                    break;
                  case 'invite':
                    context.go('/invite');
                    break;
                  case 'login':
                    context.go('/login');
                    break;
                  case 'landing':
                    context.go('/landing');
                    break;
                  case 'logout':
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'landing',
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined, color: kTextSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tree',
                  child: Row(
                    children: [
                      Icon(Icons.account_tree_outlined, color: kTextSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Family Tree'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search, color: kTextSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Search'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined, color: kTextSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Invite'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login_rounded, color: kTextSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Text('Sign In'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: kErrorColor),
                      SizedBox(width: AppSpacing.sm),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(height: 1, color: kDividerColor.withOpacity(0.5)),
      ],
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
    return Scaffold(
      appBar: AppHeader(
        title: title,
        showBackButton: showBackButton,
        actions: actions,
      ),
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

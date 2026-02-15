import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

/// Consistent app header with navigation
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )
          : Row(
              children: [
                Icon(Icons.account_tree, size: 28, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'MyFamilyTree',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            )
          : null,
      actions: actions ??
          [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (value) {
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'landing',
                  child: Row(
                    children: [
                      Icon(Icons.home_outlined, color: kPrimaryColor),
                      SizedBox(width: AppSpacing.sm),
                      Text('Home'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tree',
                  child: Row(
                    children: [
                      Icon(Icons.account_tree, color: kPrimaryColor),
                      SizedBox(width: AppSpacing.sm),
                      Text('Family Tree'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search, color: kPrimaryColor),
                      SizedBox(width: AppSpacing.sm),
                      Text('Search'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'invite',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: kPrimaryColor),
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
                      Icon(Icons.login, color: kSecondaryColor),
                      SizedBox(width: AppSpacing.sm),
                      Text('Sign In'),
                    ],
                  ),
                ),
              ],
            ),
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
        decoration: BoxDecoration(
          color: kPrimaryDark,
          border: Border(
            top: BorderSide(color: kDividerColor, width: 1),
          ),
        ),
        child: Center(
          child: Text(
            '© 2026 MyFamilyTree. Built with ❤️',
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
      decoration: BoxDecoration(
        color: kPrimaryDark,
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

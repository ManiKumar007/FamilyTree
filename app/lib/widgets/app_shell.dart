import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/notifications_service.dart';

/// Navigation destination definition
class _NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}

const _destinations = [
  _NavDestination(
    label: 'Family Tree',
    icon: Icons.account_tree_outlined,
    activeIcon: Icons.account_tree,
    path: '/tree',
  ),
  _NavDestination(
    label: 'Search',
    icon: Icons.search_outlined,
    activeIcon: Icons.search,
    path: '/search',
  ),
  _NavDestination(
    label: 'Connection',
    icon: Icons.link_outlined,
    activeIcon: Icons.link,
    path: '/connection',
  ),
  _NavDestination(
    label: 'Invite',
    icon: Icons.person_add_outlined,
    activeIcon: Icons.person_add,
    path: '/invite',
  ),
  _NavDestination(
    label: 'Forum',
    icon: Icons.forum_outlined,
    activeIcon: Icons.forum,
    path: '/forum',
  ),
  _NavDestination(
    label: 'Calendar',
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    path: '/calendar',
  ),
  _NavDestination(
    label: 'Statistics',
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics,
    path: '/statistics',
  ),
];

/// The main application shell that wraps authenticated screens with a sidebar
/// navigation on desktop and a bottom navigation bar on mobile.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;

    // Desktop: sidebar
    if (width >= AppSizing.breakpointTablet) {
      return _DesktopShell(
        navigationShell: navigationShell,
        ref: ref,
      );
    }

    // Mobile: bottom navigation
    return _MobileShell(navigationShell: navigationShell);
  }
}

/// Desktop layout with persistent sidebar
class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final WidgetRef ref;

  const _DesktopShell({
    required this.navigationShell,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _Sidebar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
            },
            ref: ref,
          ),
          // Vertical divider
          Container(
            width: 1,
            color: kDividerColor.withOpacity(0.5),
          ),
          // Main content
          Expanded(
            child: navigationShell,
          ),
        ],
      ),
    );
  }
}

/// Mobile layout with bottom navigation bar
class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: kDividerColor, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
          },
          backgroundColor: kSurfaceColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: kPrimaryColor.withOpacity(0.12),
          destinations: _destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon, size: 22),
                    selectedIcon: Icon(d.activeIcon, size: 22, color: kPrimaryColor),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

/// The sidebar navigation widget with gradient background, nav items,
/// and user info at the bottom.
class _Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final WidgetRef ref;

  const _Sidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.ref,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final displayName = user?.userMetadata?['full_name'] as String? ?? 
                        email.split('@').first;

    return Container(
      width: AppSizing.sidebarWidth,
      decoration: const BoxDecoration(
        gradient: AppGradients.sidebar,
      ),
      child: Column(
        children: [
          // Logo area with notifications
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kSidebarActive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: kSidebarActive,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'MyFamilyTree',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _NotificationBell(ref: widget.ref),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (int i = 0; i < _destinations.length; i++)
                    _buildNavItem(i),
                  
                  const Spacer(),

                  // Admin link (if applicable)
                  _buildAdminLink(context),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // User section at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // User avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kSidebarActive.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Logout button
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 18,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: () async {
                    await widget.ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final dest = _destinations[index];
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => widget.onDestinationSelected(index),
              borderRadius: BorderRadius.circular(10),
              hoverColor: Colors.white.withOpacity(0.08),
              splashColor: Colors.white.withOpacity(0.12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isSelected
                      ? Colors.white.withOpacity(0.12)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    // Active indicator bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 3,
                      height: isSelected ? 20 : 0,
                      decoration: BoxDecoration(
                        color: isSelected ? kSidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: isSelected ? 10 : 13),
                    Icon(
                      isSelected ? dest.activeIcon : dest.icon,
                      color: isSelected
                          ? kSidebarActive
                          : isHovered
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dest.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isHovered
                                ? Colors.white.withOpacity(0.9)
                                : Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminLink(BuildContext context) {
    return MouseRegion(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => context.push('/admin'),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withOpacity(0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const SizedBox(width: 13),
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Notification bell icon with unread count badge
class _NotificationBell extends ConsumerStatefulWidget {
  final WidgetRef ref;
  
  const _NotificationBell({required this.ref});

  @override
  ConsumerState<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<_NotificationBell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final service = ref.read(notificationsServiceProvider);
      final count = await service.getUnreadCount();
      if (mounted) {
        setState(() { _unreadCount = count; });
      }
    } catch (e) {
      // Silently fail for notification badge
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () {
            context.push('/notifications');
            // Reload count after returning from notifications
            Future.delayed(const Duration(seconds: 1), _loadUnreadCount);
          },
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kErrorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

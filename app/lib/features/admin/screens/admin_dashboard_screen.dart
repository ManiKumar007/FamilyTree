import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/admin_providers.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardStatsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: kErrorColor),
              const SizedBox(height: 16),
              Text('Error: $error', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overview Cards
                Text(
                  'Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ResponsiveGrid(
                  minChildWidth: 240,
                  children: [
                  _StatCard(
                    title: 'Total Users',
                    value: stats.totalUsers.toString(),
                    icon: Icons.people,
                    color: kInfoColor,
                    subtitle: '${stats.newUsersThisWeek} this week',
                  ),
                  _StatCard(
                    title: 'Active Users',
                    value: stats.activeUsers.toString(),
                    icon: Icons.person_outline,
                    color: kSuccessColor,
                    subtitle: 'Last 30 days',
                  ),
                  _StatCard(
                    title: 'Total People',
                    value: stats.totalPeople.toString(),
                    icon: Icons.account_tree,
                    color: kOtherColor,
                    subtitle: 'Avg ${stats.avgPeoplePerUser} per user',
                  ),
                  _StatCard(
                    title: 'Relationships',
                    value: stats.totalRelationships.toString(),
                    icon: Icons.link,
                    color: kAccentColor,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Errors Section
              Text(
                'Error Monitoring',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minChildWidth: 240,
                children: [
                  _StatCard(
                    title: 'Total Errors',
                    value: stats.totalErrors.toString(),
                    icon: Icons.bug_report,
                    color: kErrorColor,
                  ),
                  _StatCard(
                    title: 'Unresolved',
                    value: stats.unresolvedErrors.toString(),
                    icon: Icons.warning,
                    color: kWarningColor,
                  ),
                  _StatCard(
                    title: 'Error Rate (24h)',
                    value: stats.errorRate24h.toStringAsFixed(2),
                    icon: Icons.speed,
                    color: stats.errorRate24h > 5 ? kErrorColor : kSuccessColor,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minChildWidth: 140,
                children: [
                  _ActionButton(
                    label: 'View Users',
                    icon: Icons.people,
                    onPressed: () => context.push('/admin/users'),
                  ),
                  _ActionButton(
                    label: 'Error Logs',
                    icon: Icons.bug_report,
                    onPressed: () => context.push('/admin/errors'),
                  ),
                  _ActionButton(
                    label: 'Analytics',
                    icon: Icons.analytics,
                    onPressed: () => context.push('/admin/analytics'),
                  ),
                  // TODO: Implement Audit Logs screen
                  // _ActionButton(
                  //   label: 'Audit Logs',
                  //   icon: Icons.history,
                  //   onPressed: () => context.go('/admin/audit-logs'),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}

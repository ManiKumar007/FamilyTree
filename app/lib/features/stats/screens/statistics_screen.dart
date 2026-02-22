import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/stats_service.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/app_shell.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>>? _consistencyIssues;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final service = ref.read(statsServiceProvider);
      final stats = await service.getFamilyStatistics();
      final issues = await service.checkTreeConsistency();
      
      setState(() { 
        _stats = stats;
        _consistencyIssues = issues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { 
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.of(context).size.width < AppSizing.breakpointTablet
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => mobileShellScaffoldKey.currentState?.openDrawer(),
              )
            : null,
        title: const Text('Family Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Statistics',
                  subtitle: _loadError!,
                  actionLabel: 'Retry',
                  onAction: _loadStatistics,
                )
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        const SectionHeader(
                          title: 'Family Overview',
                          icon: Icons.analytics,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildOverviewGrid(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Demographics
                        const SectionHeader(
                          title: 'Demographics',
                          icon: Icons.people,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildDemographicsSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Geographic Distribution
                        const SectionHeader(
                          title: 'Geographic Distribution',
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildGeographicSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Tree Consistency
                        const SectionHeader(
                          title: 'Tree Consistency',
                          icon: Icons.verified_outlined,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildConsistencySection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewGrid() {
    if (_stats == null) return const SizedBox.shrink();
    
    return ResponsiveGrid(
      minChildWidth: 140,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _buildStatCard(
          icon: Icons.people,
          label: 'Total Members',
          value: (_stats!['total_members'] ?? 0).toString(),
          color: kPrimaryColor,
        ),
        _buildStatCard(
          icon: Icons.timeline,
          label: 'Generations',
          value: (_stats!['generation_count'] ?? 0).toString(),
          color: kAccentColor,
        ),
        _buildStatCard(
          icon: Icons.favorite,
          label: 'Living',
          value: (_stats!['living_count'] ?? 0).toString(),
          color: kSuccessColor,
        ),
        _buildStatCard(
          icon: Icons.front_hand,
          label: 'Deceased',
          value: (_stats!['deceased_count'] ?? 0).toString(),
          color: Colors.grey,
        ),
        _buildStatCard(
          icon: Icons.male,
          label: 'Male',
          value: (_stats!['male_count'] ?? 0).toString(),
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.female,
          label: 'Female',
          value: (_stats!['female_count'] ?? 0).toString(),
          color: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildDemographicsSection() {
    if (_stats == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _buildDetailRow(
              icon: Icons.cake,
              label: 'Average Age',
              value: (_stats!['avg_age'] ?? 0).toStringAsFixed(1),
              color: kAccentColor,
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.elderly,
              label: 'Oldest Member',
              value: '${_stats!['oldest_person_age'] ?? 'N/A'}',
              color: kSecondaryColor,
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.child_care,
              label: 'Youngest Member',
              value: '${_stats!['youngest_person_age'] ?? 'N/A'}',
              color: kPrimaryColor,
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.celebration,
              label: 'Married',
              value: (_stats!['married_count'] ?? 0).toString(),
              color: kRelationshipSpouse,
            ),
            const Divider(),
            _buildDetailRow(
              icon: Icons.person,
              label: 'Single',
              value: (_stats!['single_count'] ?? 0).toString(),
              color: kInfoColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeographicSection() {
    if (_stats == null) return const SizedBox.shrink();
    
    final cities = _stats!['cities'] as List<dynamic>? ?? [];
    final states = _stats!['states'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              icon: Icons.location_city,
              label: 'Total Cities',
              value: cities.length.toString(),
              color: kPrimaryColor,
            ),
            if (cities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: cities.take(10).map((city) => Chip(
                  label: Text(
                    city.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
            
            const Divider(height: AppSpacing.lg),
            
            _buildDetailRow(
              icon: Icons.map,
              label: 'Total States',
              value: states.length.toString(),
              color: kSecondaryColor,
            ),
            if (states.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: states.take(10).map((state) => Chip(
                  label: Text(
                    state.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencySection() {
    if (_consistencyIssues == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: Text('No consistency data available')),
        ),
      );
    }
    
    if (_consistencyIssues!.isEmpty) {
      return Card(
        color: kSuccessColor.withValues(alpha: 0.1),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: kSuccessColor, size: 32),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfect!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kSuccessColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Your family tree has no consistency issues.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: _consistencyIssues!.map((issue) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Icon(
              _getIssueIcon(issue['issue_type'] ?? 'error'),
              color: _getIssueColor(issue['issue_type'] ?? 'error'),
            ),
            title: Text(issue['issue_type']?.toString().toUpperCase() ?? 'ISSUE'),
            subtitle: Text(issue['description'] ?? 'No description'),
            trailing: issue['person_id'] != null 
                ? IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      // Navigate to person detail - implement navigation
                    },
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIssueIcon(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Color _getIssueColor(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'error':
        return kErrorColor;
      case 'warning':
        return kWarningColor;
      case 'info':
        return kInfoColor;
      default:
        return kTextSecondary;
    }
  }
}

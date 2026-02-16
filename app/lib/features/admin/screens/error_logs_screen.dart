import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_providers.dart';
import '../../../services/admin_service.dart';
import '../../../config/theme.dart';

class ErrorLogsScreen extends ConsumerStatefulWidget {
  const ErrorLogsScreen({super.key});

  @override
  ConsumerState<ErrorLogsScreen> createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends ConsumerState<ErrorLogsScreen> {
  String? _selectedType;
  String? _selectedSeverity;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(errorLogsProvider);
    final notifier = ref.read(errorLogsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Logs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Type',
            onSelected: (value) {
              setState(() => _selectedType = value == 'all' ? null : value);
              notifier.setFilters(type: _selectedType, severity: _selectedSeverity);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Types')),
              const PopupMenuItem(value: 'api_error', child: Text('API Error')),
              const PopupMenuItem(value: 'validation', child: Text('Validation')),
              const PopupMenuItem(value: 'database', child: Text('Database')),
              const PopupMenuItem(value: 'auth', child: Text('Authentication')),
              const PopupMenuItem(value: 'system', child: Text('System')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.priority_high),
            tooltip: 'Filter by Severity',
            onSelected: (value) {
              setState(() => _selectedSeverity = value == 'all' ? null : value);
              notifier.setFilters(type: _selectedType, severity: _selectedSeverity);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Severities')),
              const PopupMenuItem(value: 'critical', child: Text('Critical')),
              const PopupMenuItem(value: 'error', child: Text('Error')),
              const PopupMenuItem(value: 'warning', child: Text('Warning')),
              const PopupMenuItem(value: 'info', child: Text('Info')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadErrors(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters display
          if (_selectedType != null || _selectedSeverity != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceVariant,
              child: Row(
                children: [
                  const Text('Filters: '),
                  if (_selectedType != null) ...[
                    Chip(
                      label: Text('Type: $_selectedType'),
                      onDeleted: () {
                        setState(() => _selectedType = null);
                        notifier.setFilters(type: null, severity: _selectedSeverity);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_selectedSeverity != null)
                    Chip(
                      label: Text('Severity: $_selectedSeverity'),
                      onDeleted: () {
                        setState(() => _selectedSeverity = null);
                        notifier.setFilters(type: _selectedType, severity: null);
                      },
                    ),
                ],
              ),
            ),
          
          // Errors list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.errors.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, size: 64, color: kSuccessColor),
                            SizedBox(height: 16),
                            Text('No errors found', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: state.errors.length,
                        itemBuilder: (context, index) {
                          final error = state.errors[index];
                          return _ErrorLogCard(
                            error: error,
                            onResolve: () async {
                              await notifier.resolveError(error.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error marked as resolved')),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),

          // Pagination
          if (state.pagination.totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.pagination.page > 1
                        ? () => notifier.loadErrors(page: state.pagination.page - 1)
                        : null,
                  ),
                  Text(
                    'Page ${state.pagination.page} of ${state.pagination.totalPages}',
                    style: theme.textTheme.bodyLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.pagination.page < state.pagination.totalPages
                        ? () => notifier.loadErrors(page: state.pagination.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorLogCard extends StatelessWidget {
  final ErrorLog error;
  final VoidCallback onResolve;

  const _ErrorLogCard({
    required this.error,
    required this.onResolve,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return kErrorColor;
      case 'error':
        return kAccentColor;
      case 'warning':
        return kWarningColor;
      case 'info':
        return kInfoColor;
      default:
        return kTextDisabled;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      default:
        return Icons.bug_report;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(
          _getSeverityIcon(error.severity),
          color: _getSeverityColor(error.severity),
          size: 32,
        ),
        title: Text(
          error.errorType.replaceAll('_', ' ').toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              error.message.length > 100
                  ? '${error.message.substring(0, 100)}...'
                  : error.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(error.severity.toUpperCase()),
                  backgroundColor: _getSeverityColor(error.severity).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _getSeverityColor(error.severity),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                if (error.statusCode != null)
                  Chip(
                    label: Text('${error.statusCode}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                const Spacer(),
                if (error.resolved)
                  const Chip(
                    label: Text('RESOLVED'),
                    backgroundColor: kSuccessColor,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Full Message:',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(error.message),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text('Occurred: ${dateFormat.format(error.timestamp)}'),
                  ],
                ),
                if (error.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: kSuccessColor),
                      const SizedBox(width: 4),
                      Text('Resolved: ${dateFormat.format(error.resolvedAt!)}'),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (!error.resolved)
                  ElevatedButton.icon(
                    onPressed: onResolve,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessColor,
                      foregroundColor: Colors.white,
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

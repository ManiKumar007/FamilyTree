import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../providers/providers.dart';
import '../../../config/theme.dart';

class MergeReviewScreen extends ConsumerStatefulWidget {
  final String mergeRequestId;

  const MergeReviewScreen({super.key, required this.mergeRequestId});

  @override
  ConsumerState<MergeReviewScreen> createState() => _MergeReviewScreenState();
}

class _MergeReviewScreenState extends ConsumerState<MergeReviewScreen> {
  bool _isLoading = false;
  String? _error;
  MergeRequest? _mergeRequest;
  Person? _targetPerson;
  Person? _matchedPerson;
  final Map<String, dynamic> _resolvedFields = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      final merges = await api.getPendingMergeRequests();
      _mergeRequest = merges.firstWhere(
        (m) => m.id == widget.mergeRequestId,
        orElse: () => throw Exception('Merge request not found'),
      );

      _targetPerson = await api.getPerson(_mergeRequest!.targetPersonId);
      _matchedPerson = await api.getPerson(_mergeRequest!.matchedPersonId);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _approve() async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      await api.approveMerge(widget.mergeRequestId, resolvedFields: _resolvedFields);
      ref.invalidate(familyTreeProvider);
      ref.invalidate(pendingMergesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trees merged successfully!')),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _reject() async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      await api.rejectMerge(widget.mergeRequestId);
      ref.invalidate(pendingMergesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merge request rejected')),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _mergeRequest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Connection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _mergeRequest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Connection')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Connection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Explanation
                Card(
                  color: kAccentColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.merge_type, size: 40, color: kAccentColor),
                        const SizedBox(height: 8),
                        Text(
                          'Possible Family Connection',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Someone in another family tree has the same phone number as a member of your tree. '
                          'This might mean your families are connected! Review the details below.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Side-by-side comparison
                if (_targetPerson != null && _matchedPerson != null) ...[
                  Text('Profile Comparison', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _comparisonTable(),
                ],

                // Conflict resolution
                if (_mergeRequest != null && _mergeRequest!.fieldConflicts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Resolve Differences', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._mergeRequest!.fieldConflicts.entries.map((entry) {
                    final field = entry.key;
                    final conflict = entry.value as Map<String, dynamic>;
                    return _conflictResolver(field, conflict['target'], conflict['matched']);
                  }),
                ],

                const SizedBox(height: 24),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _reject,
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Not the Same Person'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _approve,
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Merge Trees'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _comparisonTable() {
    final target = _targetPerson!;
    final matched = _matchedPerson!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
          },
          children: [
            _tableRow('', 'Their Tree', 'Your Tree', isHeader: true),
            _tableRow('Name', target.name, matched.name),
            _tableRow('Phone', target.phone, matched.phone),
            _tableRow('Gender', target.gender, matched.gender),
            if (target.dateOfBirth != null || matched.dateOfBirth != null)
              _tableRow('DOB', target.dateOfBirth ?? '-', matched.dateOfBirth ?? '-'),
            _tableRow('City', target.city ?? '-', matched.city ?? '-'),
            _tableRow('Occupation', target.occupation ?? '-', matched.occupation ?? '-'),
          ],
        ),
      ),
    );
  }

  TableRow _tableRow(String label, String val1, String val2, {bool isHeader = false}) {
    final style = isHeader
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
        : const TextStyle(fontSize: 12);
    final mismatch = !isHeader && val1 != val2;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          color: mismatch ? Colors.yellow[50] : null,
          child: Text(val1, style: style),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          color: mismatch ? Colors.yellow[50] : null,
          child: Text(val2, style: style),
        ),
      ],
    );
  }

  Widget _conflictResolver(String field, dynamic targetVal, dynamic matchedVal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _choiceChip('$targetVal', field, targetVal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choiceChip('$matchedVal', field, matchedVal),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String label, String field, dynamic value) {
    final isSelected = _resolvedFields[field] == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() { _resolvedFields[field] = value; });
      },
    );
  }
}

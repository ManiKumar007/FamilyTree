import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../services/auth_service.dart';
import '../../../models/models.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _selectedDepth = 3;
  String? _selectedOccupation;
  String? _selectedMaritalStatus;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _doSearch();
      }
    });
  }

  void _doSearch() {
    ref.read(searchProvider.notifier).search(
      query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      occupation: _selectedOccupation,
      maritalStatus: _selectedMaritalStatus,
      depth: _selectedDepth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.search_rounded, size: 22, color: kPrimaryColor),
            const SizedBox(width: 8),
            const Text('Search Network'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withValues(alpha: 0.5)),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More options',
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: kErrorColor),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveContent(
        child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _doSearch(),
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search by name, occupation, city, state...',
                          hintStyle: TextStyle(color: kTextDisabled, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: kTextSecondary),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  tooltip: 'Clear search',
                                ),
                              IconButton(
                                icon: Icon(
                                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                ),
                                onPressed: () => setState(() { _showFilters = !_showFilters; }),
                                tooltip: _showFilters ? 'Hide filters' : 'Show filters',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _doSearch,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 48),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),

                // Filters
                if (_showFilters) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filters', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),

                          // Depth slider
                          Row(
                            children: [
                              const Text('Circles (depth): '),
                              Expanded(
                                child: Slider(
                                  value: _selectedDepth.toDouble(),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  label: '$_selectedDepth',
                                  onChanged: (v) => setState(() { _selectedDepth = v.round(); }),
                                ),
                              ),
                              Text('$_selectedDepth'),
                            ],
                          ),

                          // Marital status filter
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedMaritalStatus,
                            decoration: const InputDecoration(
                              labelText: 'Marital Status',
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Any')),
                              DropdownMenuItem(value: 'single', child: Text('Single')),
                              DropdownMenuItem(value: 'married', child: Text('Married')),
                              DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                              DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                            ],
                            onChanged: (v) => setState(() { _selectedMaritalStatus = v; }),
                          ),
                          const SizedBox(height: 12),

                          // Occupation filter
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Occupation',
                              isDense: true,
                              hintText: 'e.g. doctor, engineer',
                            ),
                            onChanged: (v) => _selectedOccupation = v.isEmpty ? null : v,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Results
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: kWarningColor),
                              const SizedBox(height: 16),
                              Text(
                                searchState.error!.contains('Profile not found') || searchState.error!.contains('profile setup')
                                    ? 'Profile Setup Required'
                                    : searchState.error!.contains('Session expired')
                                    ? 'Session Expired'
                                    : searchState.error!.contains('Service unavailable') || searchState.error!.contains('temporarily unavailable')
                                    ? 'Service Unavailable'
                                    : 'Search Error',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  searchState.error!,
                                  style: TextStyle(color: kTextSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (searchState.error!.contains('Profile not found') || searchState.error!.contains('profile setup'))
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/profile-setup'),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Set Up Profile'),
                                )
                              else if (searchState.error!.contains('Service unavailable') || searchState.error!.contains('temporarily unavailable'))
                                ElevatedButton.icon(
                                  onPressed: _doSearch,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                )
                              else if (searchState.error!.contains('Session expired'))
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await ref.read(authServiceProvider).signOut();
                                    if (context.mounted) context.go('/login');
                                  },
                                  icon: const Icon(Icons.logout),
                                  label: const Text('Sign In Again'),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: _doSearch,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Try Again'),
                                ),
                            ],
                          ),
                        ),
                      )
                    : searchState.results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search, size: 64, color: kTextDisabled),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchState.query.isEmpty
                                        ? 'Search Your Family Network'
                                        : 'No results found',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchState.query.isEmpty
                                        ? 'Find family members by any of the following:'
                                        : 'Try adjusting your search or filters',
                                    style: TextStyle(color: kTextSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (searchState.query.isEmpty) ...[
                                    const SizedBox(height: 24),
                                    _SearchHintChip(icon: Icons.person, label: 'Name'),
                                    _SearchHintChip(icon: Icons.work, label: 'Occupation (e.g., "Engineer", "Doctor")'),
                                    _SearchHintChip(icon: Icons.location_city, label: 'City (e.g., "Bangalore", "Delhi")'),
                                    _SearchHintChip(icon: Icons.map, label: 'State (e.g., "Karnataka", "Maharashtra")'),
                                    _SearchHintChip(icon: Icons.business, label: 'Company name'),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Or use filters above to narrow your search',
                                      style: TextStyle(
                                        color: kTextSecondary,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchState.results.length,
                            itemBuilder: (context, index) {
                              final result = searchState.results[index];
                              return _SearchResultCard(result: result);
                            },
                          ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;

  const _SearchResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final p = result.person;
    final isMale = p.gender == 'male';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMale ? kMaleColor : kFemaleColor,
          child: Icon(
            isMale ? Icons.person : Icons.person_2,
            color: Colors.white,
          ),
        ),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.occupation != null)
              Text(p.occupation!, style: TextStyle(fontSize: 12, color: kTextSecondary)),
            if (p.city != null || p.state != null)
              Text('${p.city ?? ''}, ${p.state ?? ''}', style: TextStyle(fontSize: 12, color: kTextSecondary)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${result.depth} circle${result.depth > 1 ? 's' : ''} away',
                    style: TextStyle(fontSize: 11, color: kPrimaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  p.maritalStatus,
                  style: TextStyle(fontSize: 11, color: kTextDisabled),
                ),
              ],
            ),
            if (result.connectionPath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Via: ${result.connectionPath}',
                  style: TextStyle(fontSize: 11, color: kTextDisabled, fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/person/${p.id}'),
      ),
    );
  }
}

class _SearchHintChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SearchHintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

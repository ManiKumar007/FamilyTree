import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/api_service.dart';
import '../../../services/life_events_service.dart';
import '../../../models/models.dart';
import '../../../config/theme.dart';
import '../../../config/responsive.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/image_upload_widget.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> with SingleTickerProviderStateMixin {
  Person? _person;
  List<Relationship>? _relationships;
  List<LifeEvent>? _lifeEvents;
  bool _isLoading = true;
  String? _loadError;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPerson();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadPerson() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final person = await api.getPerson(widget.personId);
      setState(() { _person = person; });

      // Load relationships separately — don't let this failure hide the person
      try {
        final rels = await api.getRelationships(widget.personId);
        setState(() { _relationships = rels; });
      } catch (relError) {
        print('⚠️ Failed to load relationships: $relError');
      }

      // Load life events separately
      try {
        final lifeEventsService = ref.read(lifeEventsServiceProvider);
        final events = await lifeEventsService.getLifeEventsByPerson(widget.personId);
        setState(() { _lifeEvents = events; });
      } catch (eventError) {
        print('⚠️ Failed to load life events: $eventError');
      }
    } catch (e) {
      setState(() { _loadError = e.toString().replaceAll('Exception: ', ''); });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading person: $e')),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.person_off,
                title: 'Person Not Found',
                subtitle: 'This person could not be loaded',
              ),
              if (_loadError != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _loadError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPerson,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(_person!),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                _buildQuickStats(_person!),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: kPrimaryColor,
                unselectedLabelColor: kTextSecondary,
                indicatorColor: kPrimaryColor,
                tabs: const [
                  Tab(text: 'Info', icon: Icon(Icons.info_outline, size: 20)),
                  Tab(text: 'Family', icon: Icon(Icons.people_outline, size: 20)),
                  Tab(text: 'Timeline', icon: Icon(Icons.timeline, size: 20)),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(_person!),
                _buildFamilyTab(_person!),
                _buildTimelineTab(_person!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Person person) {
    final genderColor = getGenderColor(person.gender);
    final r = Responsive(context);
    return SliverAppBar(
      expandedHeight: r.appBarExpandedHeight,
      pinned: true,
      backgroundColor: kSurfaceColor,
      foregroundColor: kTextPrimary,
      surfaceTintColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => context.push('/edit-profile/${person.id}'),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          onPressed: () => _sharePerson(person),
          tooltip: 'Share',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                genderColor,
                genderColor.withValues(alpha: 0.7),
                kPrimaryColor.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Hero(
                  tag: 'person-${person.id}',
                  child: GestureDetector(
                    onTap: () {
                      if (person.photoUrl != null && person.photoUrl!.isNotEmpty) {
                        ImagePreviewDialog.show(context, person.photoUrl!, person.name);
                      }
                    },
                    child: AppAvatar(
                      imageUrl: person.photoUrl,
                      gender: person.gender,
                      name: person.name,
                      size: AppSizing.avatarXl,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  person.phone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (person.verified)
                      const StatusBadge(
                        label: 'Verified',
                        color: Colors.white,
                        icon: Icons.verified,
                      ),
                    if (person.verified && !person.isAlive)
                      const SizedBox(width: AppSpacing.xs),
                    if (!person.isAlive)
                      const StatusBadge(
                        label: 'Deceased',
                        color: Colors.grey,
                        icon: Icons.front_hand,
                      ),
                  ],
                ),
                if (!person.isAlive && person.dateOfDeath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      _formatDate(person.dateOfDeath!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Person person) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (person.age != null)
            Expanded(
              child: _buildStatCard(
                icon: Icons.cake,
                label: 'Age',
                value: '${person.age}',
                color: kAccentColor,
              ),
            ),
          if (person.age != null) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: person.gender == 'male' ? Icons.male : Icons.female,
              label: 'Gender',
              value: person.gender.toUpperCase(),
              color: getGenderColor(person.gender),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: 'Status',
              value: _formatMaritalStatus(person.maritalStatus),
              color: kRelationshipSpouse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
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
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(Person person) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Personal Information',
            icon: Icons.person,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (person.dateOfBirth != null)
                    DetailRow(
                      icon: Icons.cake,
                      label: 'Date of Birth',
                      value: _formatDate(person.dateOfBirth!),
                      iconColor: kAccentColor,
                    ),
                  if (!person.isAlive && person.dateOfDeath != null)
                    DetailRow(
                      icon: Icons.front_hand,
                      label: 'Date of Death',
                      value: _formatDate(person.dateOfDeath!),
                      iconColor: Colors.grey,
                    ),
                  if (!person.isAlive && person.placeOfDeath != null)
                    DetailRow(
                      icon: Icons.location_on,
                      label: 'Place of Death',
                      value: person.placeOfDeath!,
                      iconColor: Colors.grey,
                    ),
                  if (person.occupation != null)
                    DetailRow(
                      icon: Icons.work,
                      label: 'Occupation',
                      value: person.occupation!,
                      iconColor: kPrimaryColor,
                    ),
                  if (person.community != null)
                    DetailRow(
                      icon: Icons.groups,
                      label: 'Community',
                      value: person.community!,
                      iconColor: kSecondaryColor,
                    ),
                  if (person.gotra != null)
                    DetailRow(
                      icon: Icons.family_restroom,
                      label: 'Gotra',
                      value: person.gotra!,
                      iconColor: kSecondaryColor,
                    ),
                  DetailRow(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: person.gender.toUpperCase(),
                    iconColor: getGenderColor(person.gender),
                  ),
                  DetailRow(
                    icon: Icons.favorite,
                    label: 'Marital Status',
                    value: _formatMaritalStatus(person.maritalStatus),
                    iconColor: kRelationshipSpouse,
                  ),
                  if (person.weddingDate != null)
                    DetailRow(
                      icon: Icons.celebration,
                      label: 'Wedding Date',
                      value: _formatDate(person.weddingDate!),
                      iconColor: kRelationshipSpouse,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(
            title: 'Contact Information',
            icon: Icons.contact_phone,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  DetailRow(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: person.phone,
                    iconColor: kSuccessColor,
                  ),
                  if (person.email != null && person.email!.isNotEmpty)
                    DetailRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: person.email!,
                      iconColor: kInfoColor,
                    ),
                  if (person.city != null && person.city!.isNotEmpty)
                    DetailRow(
                      icon: Icons.location_city,
                      label: 'City',
                      value: person.city!,
                      iconColor: kPrimaryColor,
                    ),
                  if (person.state != null && person.state!.isNotEmpty)
                    DetailRow(
                      icon: Icons.map,
                      label: 'State',
                      value: person.state!,
                      iconColor: kSecondaryColor,
                    ),
                ],
              ),
            ),
          ),
          if (person.nativePlace != null || 
              person.ancestralVillage != null ||
              person.nakshatra != null ||
              person.rashi != null ||
              person.subCaste != null ||
              person.kulaDevata != null ||
              person.pravara != null) ...[
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(
              title: 'Heritage & Cultural Information',
              icon: Icons.temple_hindu,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    if (person.nativePlace != null)
                      DetailRow(
                        icon: Icons.home_work,
                        label: 'Native Place',
                        value: person.nativePlace!,
                        iconColor: kPrimaryColor,
                      ),
                    if (person.ancestralVillage != null)
                      DetailRow(
                        icon: Icons.landscape,
                        label: 'Ancestral Village',
                        value: person.ancestralVillage!,
                        iconColor: kSecondaryColor,
                      ),
                    if (person.nakshatra != null)
                      DetailRow(
                        icon: Icons.stars,
                        label: 'Nakshatra',
                        value: person.nakshatra!,
                        iconColor: kAccentColor,
                      ),
                    if (person.rashi != null)
                      DetailRow(
                        icon: Icons.circle,
                        label: 'Rashi',
                        value: person.rashi!,
                        iconColor: kAccentColor,
                      ),
                    if (person.subCaste != null)
                      DetailRow(
                        icon: Icons.people,
                        label: 'Sub-Caste',
                        value: person.subCaste!,
                        iconColor: kSecondaryColor,
                      ),
                    if (person.kulaDevata != null)
                      DetailRow(
                        icon: Icons.self_improvement,
                        label: 'Kula Devata',
                        value: person.kulaDevata!,
                        iconColor: kPrimaryColor,
                      ),
                    if (person.pravara != null)
                      DetailRow(
                        icon: Icons.auto_awesome,
                        label: 'Pravara',
                        value: person.pravara!,
                        iconColor: kSecondaryColor,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilyTab(Person person) {
    if (_relationships == null || _relationships!.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No Family Connections',
        subtitle: 'Add family members to see relationships here',
      );
    }

    // Group relationships by type
    final parents = <Relationship>[];
    final children = <Relationship>[];
    final spouses = <Relationship>[];
    final siblings = <Relationship>[];

    for (final rel in _relationships!) {
      final type = rel.type.toUpperCase();
      if (type == 'FATHER_OF' || type == 'MOTHER_OF') {
        children.add(rel);
      } else if (type == 'CHILD_OF') {
        parents.add(rel);
      } else if (type.contains('SPOUSE')) {
        spouses.add(rel);
      } else if (type.contains('SIBLING')) {
        siblings.add(rel);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parents.isNotEmpty) ...[
            const SectionHeader(title: 'Parents', icon: Icons.family_restroom),
            ...parents.map((rel) => _buildRelationshipCard(rel)),
            const SizedBox(height: AppSpacing.md),
          ],
          if (spouses.isNotEmpty) ...[
            const SectionHeader(title: 'Spouse', icon: Icons.favorite),
            ...spouses.map((rel) => _buildRelationshipCard(rel)),
            const SizedBox(height: AppSpacing.md),
          ],
          if (children.isNotEmpty) ...[
            const SectionHeader(title: 'Children', icon: Icons.child_care),
            ...children.map((rel) => _buildRelationshipCard(rel)),
            const SizedBox(height: AppSpacing.md),
          ],
          if (siblings.isNotEmpty) ...[
            const SectionHeader(title: 'Siblings', icon: Icons.groups),
            ...siblings.map((rel) => _buildRelationshipCard(rel)),
          ],
        ],
      ),
    );
  }

  Widget _buildRelationshipCard(Relationship rel) {
    // This is a simplified version - in a real app, you'd fetch the related person's details
    return Card(
      child: ListTile(
        leading: AppAvatar(
          imageUrl: rel.relatedPerson?.photoUrl,
          gender: rel.relatedPerson?.gender ?? 'other',
          size: AppSizing.avatarSm,
        ),
        title: Text(rel.relatedPerson?.name ?? 'Family Member'),
        subtitle: RelationshipChip(relationshipType: rel.type),
        onTap: () => context.push('/person/${rel.relatedPersonId}'),
      ),
    );
  }

  Widget _buildTimelineTab(Person person) {
    final events = <Map<String, dynamic>>[];
    
    // Add life events from API
    if (_lifeEvents != null) {
      for (final event in _lifeEvents!) {
        events.add({
          'icon': _getEventIcon(event.eventType),
          'title': event.eventType,
          'subtitle': event.description,
          'location': event.location,
          'date': event.eventDate,
          'color': kPrimaryColor,
          'isLifeEvent': true,
          'eventId': event.id,
          'photos': event.photos,
        });
      }
    }
    
    // Add person milestones
    if (person.createdAt != null) {
      events.add({
        'icon': Icons.person_add,
        'title': 'Profile Created',
        'date': person.createdAt!,
        'color': kSuccessColor,
        'isLifeEvent': false,
      });
    }
    
    if (person.dateOfBirth != null) {
      events.add({
        'icon': Icons.cake,
        'title': 'Born',
        'date': person.dateOfBirth!,
        'color': kAccentColor,
        'isLifeEvent': false,
      });
    }
    
    if (person.weddingDate != null) {
      events.add({
        'icon': Icons.celebration,
        'title': 'Married',
        'date': person.weddingDate!,
        'color': kRelationshipSpouse,
        'isLifeEvent': false,
      });
    }

    if (!person.isAlive && person.dateOfDeath != null) {
      events.add({
        'icon': Icons.front_hand,
        'title': 'Passed Away',
        'date': person.dateOfDeath!,
        'color': Colors.grey,
        'isLifeEvent': false,
      });
    }

    if (events.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline,
        title: 'No Timeline Events',
        subtitle: 'Timeline events will appear here',
      );
    }

    // Sort events by date (oldest first for timeline)
    events.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date']);
        final dateB = DateTime.parse(b['date']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildTimelineItem(
          icon: event['icon'],
          title: event['title'],
          subtitle: event['subtitle'],
          location: event['location'],
          date: _formatDate(event['date']),
          color: event['color'],
          isLast: index == events.length - 1,
        );
      },
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'birth':
        return Icons.cake;
      case 'marriage':
        return Icons.favorite;
      case 'death':
        return Icons.front_hand;
      case 'education':
        return Icons.school;
      case 'graduation':
        return Icons.school;
      case 'job_start':
        return Icons.work;
      case 'job_end':
        return Icons.work_off;
      case 'retirement':
        return Icons.beach_access;
      case 'relocation':
        return Icons.moving;
      case 'immigration':
        return Icons.flight;
      case 'achievement':
        return Icons.emoji_events;
      case 'health':
        return Icons.local_hospital;
      case 'travel':
        return Icons.flight_takeoff;
      case 'other':
        return Icons.event;
      default:
        return Icons.event;
    }
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? location,
    required String date,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: kDividerColor,
                    margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                      if (location != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: kTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMaritalStatus(String status) {
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  void _sharePerson(Person person) {
    Share.share(
      'Check out ${person.name} on MyFamilyTree!\nPhone: ${person.phone}',
      subject: 'MyFamilyTree - ${person.name}',
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: kSurfaceColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

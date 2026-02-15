import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../config/theme.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  Person? _person;
  List<Relationship>? _relationships;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  Future<void> _loadPerson() async {
    setState(() { _isLoading = true; });
    try {
      final api = ref.read(apiServiceProvider);
      final person = await api.getPerson(widget.personId);
      final rels = await api.getRelationships(widget.personId);
      setState(() { _person = person; _relationships = rels; });
    } catch (e) {
      // handle error
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
        body: const Center(child: Text('Person not found')),
      );
    }

    final p = _person!;
    final isMale = p.gender == 'male';

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/edit-profile/${p.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Card(
                  color: isMale ? kMaleColor.withOpacity(0.3) : kFemaleColor.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: isMale ? kMaleColor : kFemaleColor,
                          child: p.photoUrl != null
                              ? ClipOval(
                                  child: Image.network(p.photoUrl!, width: 80, height: 80, fit: BoxFit.cover),
                                )
                              : Icon(isMale ? Icons.person : Icons.person_2, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              if (p.age != null)
                                Text('Age: ${p.age}', style: TextStyle(color: Colors.grey[600])),
                              if (p.city != null || p.state != null)
                                Text('${p.city ?? ''}, ${p.state ?? ''}', style: TextStyle(color: Colors.grey[600])),
                              Row(
                                children: [
                                  if (p.verified)
                                    Chip(
                                      avatar: const Icon(Icons.verified, size: 14, color: Colors.green),
                                      label: const Text('Verified', style: TextStyle(fontSize: 12)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  if (!p.verified)
                                    Chip(
                                      label: const Text('Not yet joined', style: TextStyle(fontSize: 12)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Details', style: Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        _infoRow('Gender', p.gender),
                        if (p.dateOfBirth != null) _infoRow('Date of Birth', p.dateOfBirth!),
                        _infoRow('Marital Status', p.maritalStatus),
                        if (p.occupation != null) _infoRow('Occupation', p.occupation!),
                        if (p.community != null) _infoRow('Community', p.community!),
                        if (p.phone.isNotEmpty) _infoRow('Phone', p.phone),
                        if (p.email != null) _infoRow('Email', p.email!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Relationships
                if (_relationships != null && _relationships!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Family Connections', style: Theme.of(context).textTheme.titleMedium),
                          const Divider(),
                          ..._relationships!.map((rel) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _relationshipIcon(rel.type),
                              color: kPrimaryColor,
                            ),
                            title: Text(rel.relatedPerson?.name ?? 'Unknown'),
                            subtitle: Text(_relationshipLabel(rel.type)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/person/${rel.relatedPersonId}'),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],

                // Invite button if not verified
                if (!p.verified) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/invite'),
                    icon: const Icon(Icons.send),
                    label: Text('Invite ${p.name} to join'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  IconData _relationshipIcon(String type) {
    switch (type) {
      case 'FATHER_OF':
      case 'MOTHER_OF': return Icons.arrow_upward;
      case 'CHILD_OF': return Icons.arrow_downward;
      case 'SPOUSE_OF': return Icons.favorite;
      case 'SIBLING_OF': return Icons.people;
      default: return Icons.link;
    }
  }

  String _relationshipLabel(String type) {
    switch (type) {
      case 'FATHER_OF': return 'Father of';
      case 'MOTHER_OF': return 'Mother of';
      case 'CHILD_OF': return 'Child of';
      case 'SPOUSE_OF': return 'Spouse of';
      case 'SIBLING_OF': return 'Sibling of';
      default: return type;
    }
  }
}

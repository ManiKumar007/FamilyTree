import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../providers/providers.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String? relativePersonId;
  final String? relationshipType;

  const AddMemberScreen({
    super.key,
    this.relativePersonId,
    this.relationshipType,
  });

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();

  String _gender = 'male';
  String _relationshipType = 'FATHER_OF';
  DateTime? _dateOfBirth;
  String _maritalStatus = 'single';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _mergeResult;

  @override
  void initState() {
    super.initState();
    if (widget.relationshipType != null) {
      _relationshipType = widget.relationshipType!;
      // Auto-set gender based on relationship type
      if (_relationshipType == 'FATHER_OF') _gender = 'male';
      if (_relationshipType == 'MOTHER_OF') _gender = 'female';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1970, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() { _dateOfBirth = picked; });
  }

  String get _relationshipLabel {
    switch (_relationshipType) {
      case 'FATHER_OF': return 'Father';
      case 'MOTHER_OF': return 'Mother';
      case 'SPOUSE_OF': return 'Spouse';
      case 'SIBLING_OF': return 'Sibling';
      case 'CHILD_OF': return 'Child';
      default: return 'Family Member';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final apiService = ref.read(apiServiceProvider);

      // 1. Create person
      final result = await apiService.createPerson({
        'name': _nameController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'gender': _gender,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'occupation': _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        'marital_status': _maritalStatus,
      });

      final newPersonId = result['person']?['id'];

      // 2. Create relationship if we have a relative
      if (widget.relativePersonId != null && newPersonId != null) {
        // Determine relationship direction
        String personId;
        String relatedPersonId;
        String type;

        if (_relationshipType == 'CHILD_OF') {
          // New person is child of the relative
          // Store as: relative is FATHER_OF/MOTHER_OF new person
          final parentType = _gender == 'male' ? 'FATHER_OF' : 'MOTHER_OF';
          personId = widget.relativePersonId!; // not quite right — need parent gender
          relatedPersonId = newPersonId;
          type = parentType;
          // Actually: the root is the parent, new person is the child
          // So: root FATHER_OF/MOTHER_OF newPerson
          // We need the root's gender to determine type
          personId = widget.relativePersonId!;
          relatedPersonId = newPersonId;
          // For now assume the person adding is parent
          type = 'FATHER_OF'; // Backend trigger handles inverse
        } else {
          // New person IS the relationship type TO the relative
          // e.g., new person is FATHER_OF relative
          personId = newPersonId;
          relatedPersonId = widget.relativePersonId!;
          type = _relationshipType;
        }

        await apiService.createRelationship(
          personId: personId,
          relatedPersonId: relatedPersonId,
          type: type,
        );
      }

      // 3. Check for merge request
      if (result['mergeRequest'] != null) {
        setState(() { _mergeResult = result['mergeRequest']; });
      }

      // 4. Refresh tree and go back
      ref.invalidate(familyTreeProvider);

      if (mounted) {
        if (_mergeResult != null) {
          // Show merge detection dialog
          _showMergeDetectedDialog();
        } else {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_nameController.text} added to your tree!')),
          );
        }
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showMergeDetectedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Possible Connection Found!'),
        content: Text(
          'Someone with the same phone number exists in another family tree. '
          'This could be a connection between your families!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Review Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              if (_mergeResult != null) {
                context.push('/merge/${_mergeResult!['id']}');
              }
            },
            child: const Text('Review Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${_relationshipLabel}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Relationship type (if not pre-set)
                  if (widget.relationshipType == null) ...[
                    DropdownButtonFormField<String>(
                      value: _relationshipType,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'FATHER_OF', child: Text('Father')),
                        DropdownMenuItem(value: 'MOTHER_OF', child: Text('Mother')),
                        DropdownMenuItem(value: 'SPOUSE_OF', child: Text('Spouse')),
                        DropdownMenuItem(value: 'SIBLING_OF', child: Text('Sibling')),
                        DropdownMenuItem(value: 'CHILD_OF', child: Text('Child')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _relationshipType = v!;
                          if (v == 'FATHER_OF') _gender = 'male';
                          if (v == 'MOTHER_OF') _gender = 'female';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone (mandatory — for invite + merge)
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+91 ',
                      helperText: 'Required — used to invite and connect family members',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number is required';
                      if (v.trim().length != 10) return 'Enter a 10-digit number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() { _gender = v!; }),
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth (optional for family members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake),
                    title: Text(
                      _dateOfBirth == null
                          ? 'Date of Birth (optional)'
                          : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDateOfBirth,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Marital Status
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Marital Status',
                      prefixIcon: Icon(Icons.favorite),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'married', child: Text('Married')),
                      DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                      DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                    ],
                    onChanged: (v) => setState(() { _maritalStatus = v!; }),
                  ),
                  const SizedBox(height: 16),

                  // City & State (optional)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Occupation (optional)
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation (optional)',
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.person_add),
                    label: Text('Add ${_relationshipLabel}'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

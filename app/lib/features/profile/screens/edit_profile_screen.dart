import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final String personId;
  const EditProfileScreen({super.key, required this.personId});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _communityController = TextEditingController();

  String _gender = 'male';
  String _maritalStatus = 'single';
  DateTime? _dateOfBirth;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  Future<void> _loadPerson() async {
    try {
      final api = ref.read(apiServiceProvider);
      final person = await api.getPerson(widget.personId);
      _nameController.text = person.name;
      _phoneController.text = person.phone.replaceFirst('+91', '');
      _cityController.text = person.city ?? '';
      _stateController.text = person.state ?? '';
      _occupationController.text = person.occupation ?? '';
      _communityController.text = person.community ?? '';
      _gender = person.gender;
      _maritalStatus = person.maritalStatus;
      if (person.dateOfBirth != null) {
        _dateOfBirth = DateTime.tryParse(person.dateOfBirth!);
      }
    } catch (e) {
      _error = e.toString();
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _error = null; });

    try {
      final api = ref.read(apiServiceProvider);
      await api.updatePerson(widget.personId, {
        'name': _nameController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'gender': _gender,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'occupation': _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        'community': _communityController.text.trim().isEmpty ? null : _communityController.text.trim(),
        'marital_status': _maritalStatus,
      });

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _occupationController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone), prefixText: '+91 '),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().length != 10 ? '10-digit number required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() { _gender = v!; }),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake),
                    title: Text(_dateOfBirth == null
                        ? 'Date of Birth'
                        : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirth ?? DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() { _dateOfBirth = d; });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration: const InputDecoration(labelText: 'Marital Status', prefixIcon: Icon(Icons.favorite)),
                    items: const [
                      DropdownMenuItem(value: 'single', child: Text('Single')),
                      DropdownMenuItem(value: 'married', child: Text('Married')),
                      DropdownMenuItem(value: 'divorced', child: Text('Divorced')),
                      DropdownMenuItem(value: 'widowed', child: Text('Widowed')),
                    ],
                    onChanged: (v) => setState(() { _maritalStatus = v!; }),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _stateController, decoration: const InputDecoration(labelText: 'State'))),
                  ]),
                  const SizedBox(height: 16),
                  TextFormField(controller: _occupationController, decoration: const InputDecoration(labelText: 'Occupation', prefixIcon: Icon(Icons.work))),
                  const SizedBox(height: 16),
                  TextFormField(controller: _communityController, decoration: const InputDecoration(labelText: 'Community', prefixIcon: Icon(Icons.group))),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red[700])),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes'),
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

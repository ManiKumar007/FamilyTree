import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _communityController = TextEditingController();
  
  String _gender = 'male';
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  String? _error;

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

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { _dateOfBirth = picked; });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() { _error = 'Please select your date of birth'; });
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);

      // Create person record linked to the auth user
      await apiService.createPerson({
        'name': _nameController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'gender': _gender,
        'date_of_birth': _dateOfBirth!.toIso8601String().split('T')[0],
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'occupation': _occupationController.text.trim().isEmpty 
            ? null 
            : _occupationController.text.trim(),
        'community': _communityController.text.trim().isEmpty 
            ? null 
            : _communityController.text.trim(),
        'auth_user_id': authService.currentUser!.id,
        'verified': true,
      });

      // Refresh providers to load the new profile
      ref.invalidate(myProfileProvider);
      ref.invalidate(familyTreeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
        context.go('/tree');
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
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
                  Text(
                    'Tell us about yourself',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This information helps your family find and connect with you.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person),
                      helperText: 'Required',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: Icon(Icons.phone),
                      prefixText: '+91 ',
                      helperText: 'Required - 10 digits',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                      if (v.trim().length != 10) return 'Must be exactly 10 digits';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Only numbers allowed';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cake),
                    title: Text(
                      _dateOfBirth == null
                          ? 'Date of Birth *'
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

                  // City
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // State
                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Occupation (optional)
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                      prefixIcon: Icon(Icons.work),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Community (optional)
                  TextFormField(
                    controller: _communityController,
                    decoration: const InputDecoration(
                      labelText: 'Community',
                      prefixIcon: Icon(Icons.group),
                      helperText: 'Optional',
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
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save & Continue'),
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

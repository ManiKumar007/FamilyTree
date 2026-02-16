import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../providers/providers.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../widgets/form_fields.dart';

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
  String _countryCode = '+91';
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-populate name from auth metadata
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final metaName = user.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        _nameController.text = metaName;
      }
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
        'phone': '${_countryCode}${_phoneController.text.trim()}',
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
        'email': authService.currentUser!.email,
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
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizing.maxFormWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tell us about yourself',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This information helps your family find and connect with you.',
                    style: TextStyle(color: kTextSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

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
                  const SizedBox(height: AppSpacing.md),

                  // Phone
                  PhoneInputField(
                    controller: _phoneController,
                    countryCode: _countryCode,
                    onCountryCodeChanged: (v) => setState(() => _countryCode = v),
                    helperText: 'Required - 10 digits',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                      if (v.trim().length != 10) return 'Must be exactly 10 digits';
                      if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Only numbers allowed';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date of Birth
                  DatePickerField(
                    label: 'Date of Birth',
                    selectedDate: _dateOfBirth,
                    onDateSelected: (d) => setState(() { _dateOfBirth = d; }),
                    required: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc),
                    ),
                    items: FormConstants.genderOptions
                        .map((o) => o.toMenuItem())
                        .toList(),
                    onChanged: (v) => setState(() { _gender = v!; }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // City
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // State
                  StateAutocompleteField(
                    controller: _stateController,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Occupation (optional)
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Occupation',
                      prefixIcon: Icon(Icons.work),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Community (optional)
                  TextFormField(
                    controller: _communityController,
                    decoration: const InputDecoration(
                      labelText: 'Community',
                      prefixIcon: Icon(Icons.group),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Error
                  if (_error != null) ...[
                    ErrorBanner(message: _error!),
                    const SizedBox(height: AppSpacing.md),
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

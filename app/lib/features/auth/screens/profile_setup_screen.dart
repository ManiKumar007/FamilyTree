import 'dart:async';
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
  final _usernameController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _communityController = TextEditingController();
  final _gotraController = TextEditingController();
  
  String _gender = 'male';
  String _countryCode = '+91';
  DateTime? _dateOfBirth;
  bool _isLoading = false;
  String? _error;

  // Username availability state
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    // Pre-populate name from auth metadata
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      final metaName = user.userMetadata?['name'] as String?;
      if (metaName != null && metaName.isNotEmpty) {
        final parts = metaName.trim().split(RegExp(r'\s+'));
        _givenNameController.text = parts.first;
        if (parts.length > 1) {
          _surnameController.text = parts.sublist(1).join(' ');
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _givenNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _occupationController.dispose();
    _communityController.dispose();
    _gotraController.dispose();
    super.dispose();
  }

  /// Debounced username availability check
  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    final username = value.trim();

    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Local format validation first
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = 'At least 3 characters';
        _isCheckingUsername = false;
      });
      return;
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(username)) {
      setState(() {
        _isUsernameAvailable = null;
        _usernameError = 'Letters, numbers & underscores only (start with letter)';
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
      _isUsernameAvailable = null;
    });

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final api = ref.read(apiServiceProvider);
        final available = await api.checkUsernameAvailability(username);
        if (mounted && _usernameController.text.trim() == username) {
          setState(() {
            _isUsernameAvailable = available;
            _usernameError = available ? null : 'Username already taken';
            _isCheckingUsername = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isCheckingUsername = false);
        }
      }
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      setState(() { _error = 'Please select your date of birth'; });
      return;
    }
    // Validate username
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() { _error = 'Please choose a username'; });
      return;
    }
    if (_isUsernameAvailable != true) {
      setState(() { _error = 'Please choose an available username'; });
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final authService = ref.read(authServiceProvider);
      final apiService = ref.read(apiServiceProvider);

      // Check current session state
      print('\n========================================');
      print('🔍 Profile Setup - Initial State');
      print('========================================');
      final initialSession = authService.currentSession;
      final initialUser = authService.currentUser;
      print('User: ${initialUser?.email}');
      print('User ID: ${initialUser?.id}');
      print('Has Session: ${initialSession != null}');
      print('Token Length: ${authService.accessToken?.length ?? 0}');
      if (authService.accessToken != null) {
        print('Token Preview: ${authService.accessToken!.substring(0, 20)}...');
      }
      
      // Check email confirmation status
      final user = authService.currentUser;
      if (user != null) {
        print('User Email: ${user.email}');
        print('Email Confirmed: ${user.emailConfirmedAt != null}');
        print('User Created: ${user.createdAt}');
        
        // If email is not confirmed, show warning
        if (user.emailConfirmedAt == null) {
          print('⚠️ WARNING: Email not confirmed. This may cause token issues.');
        }
      }
      print('========================================\n');

      // Validate we have a user
      if (initialUser == null) {
        print('❌ No user found - redirecting to login');
        setState(() { 
          _error = 'No user session found. Please sign in.';
          _isLoading = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
        return;
      }

      // Refresh the session to ensure we have a valid token
      print('🔄 Refreshing session before profile creation...');
      print('Token BEFORE refresh: ${authService.accessToken?.substring(0, 30)}...');
      
      final refreshed = await authService.refreshSession();
      if (refreshed) {
        print('✅ Session refreshed successfully');
        // Give a moment for the session to update
        await Future.delayed(const Duration(milliseconds: 100));
        print('Token AFTER refresh: ${authService.accessToken?.substring(0, 30)}...');
      } else {
        print('⚠️ Session refresh failed - this will likely cause token errors');
        // For profile setup, we need a valid token, so show error
        setState(() {
          _error = 'Failed to refresh authentication. Please try logging in again.';
          _isLoading = false;
        });
        return;
      }

      // Create person record linked to the auth user
      final givenName = _givenNameController.text.trim();
      final surname = _surnameController.text.trim();
      final fullName = surname.isEmpty ? givenName : '$givenName $surname';

      print('📝 Creating profile for: $fullName');
      print('Phone: ${_countryCode}${_phoneController.text.trim()}');
      print('Auth User ID: ${authService.currentUser!.id}');
      
      final profileData = {
        'username': username,
        'name': fullName,
        'given_name': givenName,
        'surname': surname.isEmpty ? null : surname,
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
        'gotra': _gotraController.text.trim().isEmpty 
            ? null 
            : _gotraController.text.trim(),
        'email': authService.currentUser!.email,
        'auth_user_id': authService.currentUser!.id,
        'verified': true,
      };
      
      print('Profile data prepared: ${profileData.keys.join(", ")}');
      print('Making API call to create person...');
      
      await apiService.createPerson(profileData);
      
      print('✅ Profile created successfully!');


      // Refresh providers to load the new profile
      ref.invalidate(myProfileProvider);
      ref.invalidate(familyTreeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile created successfully!')),
        );
        context.go('/tree');
      }
    } catch (e, stackTrace) {
      print('\n❌ Error creating profile:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Check for specific error types
      if (errorMessage.contains('Service unavailable') || errorMessage.contains('authentication service') || errorMessage.contains('503')) {
        errorMessage = 'Server configuration error. The backend cannot connect to the authentication service. '
                      'Please contact the administrator or check the backend configuration.';
      } else if (errorMessage.contains('Invalid or expired token')) {
        errorMessage = 'Your session has expired. Please sign in again.';
        // Auto redirect to login after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go('/login');
        });
      } else if (errorMessage.contains('already exists')) {
        errorMessage = 'A profile with this phone number already exists.';
      } else if (errorMessage.contains('Network') || errorMessage.contains('connection')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      setState(() { _error = errorMessage; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tree'),
          tooltip: 'Back to Family Tree',
        ),
        title: const Text('Complete Your Profile'),
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

                  // Username field with real-time availability check
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: const Icon(Icons.alternate_email),
                      prefixText: '@',
                      helperText: 'Unique, 3-20 chars. Letters, numbers & underscores.',
                      suffixIcon: _isCheckingUsername
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _isUsernameAvailable == true
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : _usernameError != null
                                  ? const Icon(Icons.cancel, color: kErrorColor)
                                  : null,
                      errorText: _usernameError,
                    ),
                    onChanged: _onUsernameChanged,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 3) return 'At least 3 characters';
                      if (v.trim().length > 20) return 'Max 20 characters';
                      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(v.trim())) {
                        return 'Letters, numbers & underscores only';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Name fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _givenNameController,
                          decoration: const InputDecoration(
                            labelText: 'Given Name *',
                            prefixIcon: Icon(Icons.person),
                            helperText: 'Required',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _surnameController,
                          decoration: const InputDecoration(
                            labelText: 'Surname',
                            helperText: 'Family name',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
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
                  const SizedBox(height: AppSpacing.md),

                  // Gotra (optional)
                  TextFormField(
                    controller: _gotraController,
                    decoration: const InputDecoration(
                      labelText: 'Gotra',
                      prefixIcon: Icon(Icons.family_restroom),
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

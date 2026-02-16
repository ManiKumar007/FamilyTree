import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/api_service.dart';
import '../../../providers/providers.dart';
import '../../../models/models.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/form_fields.dart';

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
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _communityController = TextEditingController();

  String _gender = 'male';
  String _maritalStatus = 'single';
  DateTime? _dateOfBirth;
  DateTime? _weddingDate;
  Person? _currentPerson;
  XFile? _selectedImage;
  String _countryCode = '+91';
  String? _uploadedImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _error;

  /// Extract country code from a full phone number
  String _extractCountryCode(String phone) {
    for (final code in FormConstants.countryCodeValues) {
      if (phone.startsWith(code)) return code;
    }
    return '+91'; // default
  }

  /// Strip country code from a full phone number
  String _stripCountryCode(String phone) {
    for (final code in FormConstants.countryCodeValues) {
      if (phone.startsWith(code)) return phone.substring(code.length);
    }
    return phone;
  }

  @override
  void initState() {
    super.initState();
    _loadPerson();
  }

  Future<void> _loadPerson() async {
    try {
      final api = ref.read(apiServiceProvider);
      final person = await api.getPerson(widget.personId);
      _currentPerson = person;
      _nameController.text = person.name;
      _phoneController.text = _stripCountryCode(person.phone);
      _countryCode = _extractCountryCode(person.phone);
      _emailController.text = person.email ?? '';
      _cityController.text = person.city ?? '';
      _stateController.text = person.state ?? '';
      _occupationController.text = person.occupation ?? '';
      _communityController.text = person.community ?? '';
      _gender = person.gender;
      _maritalStatus = person.maritalStatus;
      if (person.dateOfBirth != null) {
        _dateOfBirth = DateTime.tryParse(person.dateOfBirth!);
      }
      if (person.weddingDate != null) {
        _weddingDate = DateTime.tryParse(person.weddingDate!);
      }
    } catch (e) {
      _error = e.toString();
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _handleImageSelected(XFile imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isUploadingImage = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final imageUrl = await api.uploadProfileImage(widget.personId, imageFile);
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to upload image: $e';
        _isUploadingImage = false;
        _selectedImage = null;
      });
    }
  }

  Future<void> _handleImageRemoved() async {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; _error = null; });

    try {
      final api = ref.read(apiServiceProvider);
      
      final updateData = {
        'name': _nameController.text.trim(),
        'phone': '${_countryCode}${_phoneController.text.trim()}',
        'gender': _gender,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'occupation': _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        'community': _communityController.text.trim().isEmpty ? null : _communityController.text.trim(),
        'marital_status': _maritalStatus,
        'wedding_date': _weddingDate?.toIso8601String().split('T')[0],
      };

      // Add email — send even if empty to allow clearing
      updateData['email'] = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();

      // Add uploaded image URL if available
      if (_uploadedImageUrl != null) {
        updateData['photo_url'] = _uploadedImageUrl;
      } else if (_selectedImage == null && _uploadedImageUrl == null) {
        // User removed the image
        updateData['photo_url'] = null;
      }

      await api.updatePerson(widget.personId, updateData);

      // Refresh providers so tree and profile show updated data
      ref.invalidate(myProfileProvider);
      ref.invalidate(familyTreeProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
        appBar: AppBar(
          title: const Text('Edit Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'View Family Tree',
              onPressed: () => context.go('/tree'),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.account_tree),
              tooltip: 'View Family Tree',
              onPressed: () => context.go('/tree'),
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isUploadingImage,
        message: 'Uploading image...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizing.maxFormWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image Upload
                    Center(
                      child: ImageUploadWidget(
                        currentImageUrl: _uploadedImageUrl ?? _currentPerson?.photoUrl,
                        gender: _gender,
                        onImageSelected: _handleImageSelected,
                        onImageRemoved: _handleImageRemoved,
                        size: AppSizing.avatarXl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        'Tap to upload profile photo (optional)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: kTextSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Personal Information Section
                    const SectionHeader(
                      title: 'Personal Information',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
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
                    
                    PhoneInputField(
                      controller: _phoneController,
                      countryCode: _countryCode,
                      onCountryCodeChanged: (v) => setState(() => _countryCode = v),
                      helperText: 'Required - 10 digits',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        helperText: 'Optional',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: FormConstants.genderOptions
                          .map((o) => o.toMenuItem())
                          .toList(),
                      onChanged: (v) => setState(() { _gender = v!; }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    DatePickerField(
                      label: 'Date of Birth',
                      selectedDate: _dateOfBirth,
                      onDateSelected: (d) => setState(() { _dateOfBirth = d; }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    DropdownButtonFormField<String>(
                      initialValue: _maritalStatus,
                      decoration: const InputDecoration(
                        labelText: 'Marital Status',
                        prefixIcon: Icon(Icons.favorite),
                      ),
                      items: FormConstants.maritalStatusOptions
                          .map((o) => o.toMenuItem())
                          .toList(),
                      onChanged: (v) => setState(() { _maritalStatus = v!; }),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    if (_maritalStatus == 'married')
                      DatePickerField(
                        label: 'Wedding Date',
                        selectedDate: _weddingDate,
                        onDateSelected: (d) => setState(() { _weddingDate = d; }),
                        icon: Icons.celebration,
                        helperText: 'Optional',
                        initialDate: DateTime.now(),
                      ),
                    if (_maritalStatus == 'married')
                      const SizedBox(height: AppSpacing.md),

                    const SizedBox(height: AppSpacing.lg),
                    
                    // Professional & Location Information
                    const SectionHeader(
                      title: 'Professional & Location',
                      icon: Icons.work,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        prefixIcon: Icon(Icons.work),
                        helperText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    TextFormField(
                      controller: _communityController,
                      decoration: const InputDecoration(
                        labelText: 'Community',
                        prefixIcon: Icon(Icons.groups),
                        helperText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              prefixIcon: Icon(Icons.location_city),
                              helperText: 'Optional',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StateAutocompleteField(
                            controller: _stateController,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Error Message
                    if (_error != null) ...[
                      ErrorBanner(message: _error!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving || _isUploadingImage ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    // Cancel Button
                    OutlinedButton(
                      onPressed: _isSaving || _isUploadingImage
                          ? null
                          : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

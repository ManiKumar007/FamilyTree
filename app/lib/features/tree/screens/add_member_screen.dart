import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../providers/providers.dart';
import '../../../config/constants.dart';
import '../../../config/theme.dart';
import '../../../widgets/form_fields.dart';

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
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();

  String _gender = 'male';
  String _countryCode = '+91';
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
      // Auto-set marital status based on relationship type
      if (_relationshipType == 'FATHER_OF' ||
          _relationshipType == 'MOTHER_OF' ||
          _relationshipType == 'SPOUSE_OF') {
        _maritalStatus = 'married';
      }
    }
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _occupationController.dispose();
    super.dispose();
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

      // Get current user's profile to use as anchor if no relative specified
      final myProfile = await ref.read(myProfileProvider.future);
      if (myProfile == null) {
        throw Exception('Profile not found. Please complete profile setup first.');
      }

      final anchorPersonId = widget.relativePersonId ?? myProfile.id;

      // 1. Create person
      final givenName = _givenNameController.text.trim();
      final surname = _surnameController.text.trim();
      final fullName = surname.isEmpty ? givenName : '$givenName $surname';

      final result = await apiService.createPerson({
        'name': fullName,
        'given_name': givenName,
        'surname': surname.isEmpty ? null : surname,
        'phone': '$_countryCode${_phoneController.text.trim()}',
        'gender': _gender,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'occupation': _occupationController.text.trim().isEmpty ? null : _occupationController.text.trim(),
        'marital_status': _maritalStatus,
      });

      final newPersonId = result['person']?['id'];

      // 2. Create relationship - always create a relationship to anchor the person to the tree
      if (newPersonId != null) {
        // Determine relationship direction
        String personId;
        String relatedPersonId;
        String type;

        if (_relationshipType == 'CHILD_OF') {
          // New person is child of the anchor (me or specified relative)
          // Store as: anchor is FATHER_OF/MOTHER_OF new person
          personId = anchorPersonId;
          relatedPersonId = newPersonId;
          // Determine parent type based on anchor's actual gender
          String anchorGender;
          if (widget.relativePersonId != null && widget.relativePersonId != myProfile.id) {
            // Fetch the anchor person's gender
            final anchorPerson = await apiService.getPerson(anchorPersonId);
            anchorGender = anchorPerson.gender;
          } else {
            anchorGender = myProfile.gender;
          }
          type = anchorGender == 'male' ? 'FATHER_OF' : 'MOTHER_OF';
        } else {
          // New person IS the relationship type TO the anchor
          // e.g., new person is FATHER_OF relative/me
          personId = newPersonId;
          relatedPersonId = anchorPersonId;
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
            SnackBar(content: Text('$fullName added to your tree!')),
          );
        }
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kDividerColor.withValues(alpha: 0.5)),
        ),
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
                  // Relationship type (if not pre-set)
                  if (widget.relationshipType == null) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _relationshipType,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      items: FormConstants.relationshipOptions
                          .map((o) => o.toMenuItem())
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _relationshipType = v!;
                          if (v == 'FATHER_OF') _gender = 'male';
                          if (v == 'MOTHER_OF') _gender = 'female';
                          // Parents and spouses are presumably married
                          if (v == 'FATHER_OF' || v == 'MOTHER_OF' || v == 'SPOUSE_OF') {
                            _maritalStatus = 'married';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

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

                  // Phone (mandatory — for invite + merge)
                  PhoneInputField(
                    controller: _phoneController,
                    countryCode: _countryCode,
                    onCountryCodeChanged: (v) => setState(() => _countryCode = v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc),
                      helperText: 'Required',
                    ),
                    items: FormConstants.genderOptions
                        .map((o) => o.toMenuItem())
                        .toList(),
                    onChanged: (v) => setState(() { _gender = v!; }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Date of Birth (optional for family members)
                  DatePickerField(
                    label: 'Date of Birth',
                    selectedDate: _dateOfBirth,
                    onDateSelected: (d) => setState(() { _dateOfBirth = d; }),
                    initialDate: DateTime(1970, 1, 1),
                    helperText: 'Optional',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Marital Status
                  DropdownButtonFormField<String>(
                    initialValue: _maritalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Marital Status',
                      prefixIcon: Icon(Icons.favorite),
                      helperText: 'Optional',
                    ),
                    items: FormConstants.maritalStatusOptions
                        .map((o) => o.toMenuItem())
                        .toList(),
                    onChanged: (v) => setState(() { _maritalStatus = v!; }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // City & State (optional)
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      helperText: 'Optional',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.lg),

                  // Error
                  if (_error != null) ...[  
                    ErrorBanner(message: _error!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Submit — right-aligned row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_rounded),
                        label: Text('Add ${_relationshipLabel}'),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../config/theme.dart';
import 'dart:developer' as developer;

/// Phone authentication dialog with OTP verification
class PhoneAuthDialog extends ConsumerStatefulWidget {
  const PhoneAuthDialog({super.key});

  @override
  ConsumerState<PhoneAuthDialog> createState() => _PhoneAuthDialogState();
}

class _PhoneAuthDialogState extends ConsumerState<PhoneAuthDialog> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _countryCode = '+91'; // Default to India
  bool _isLoading = false;
  bool _otpSent = false;
  String? _error;
  String? _phoneNumber;

  // List of common country codes
  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'country': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'country': 'USA/Canada', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'country': 'UAE', 'flag': '🇦🇪'},
    {'code': '+61', 'country': 'Australia', 'flag': '🇦🇺'},
    {'code': '+65', 'country': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+86', 'country': 'China', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'Japan', 'flag': '🇯🇵'},
    {'code': '+82', 'country': 'South Korea', 'flag': '🇰🇷'},
    {'code': '+49', 'country': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'France', 'flag': '🇫🇷'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) {
      developer.log('❌ Form validation failed', name: 'PhoneAuthDialog');
      return;
    }

    final phone = _phoneController.text.trim();
    _phoneNumber = '$_countryCode$phone';
    
    developer.log('📱 Sending OTP', name: 'PhoneAuthDialog', error: {'phone': _phoneNumber});
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithPhone(_phoneNumber!);
      
      developer.log('✅ OTP sent successfully', name: 'PhoneAuthDialog');
      
      if (mounted) {
        setState(() { 
          _otpSent = true; 
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to $_phoneNumber'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to send OTP',
        name: 'PhoneAuthDialog',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() { 
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() { _error = 'Please enter the OTP code'; });
      return;
    }

    final otp = _otpController.text.trim();
    developer.log('🔐 Verifying OTP', name: 'PhoneAuthDialog');
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneOTP(
        phoneNumber: _phoneNumber!,
        otpCode: otp,
      );
      
      developer.log('✅ OTP verified successfully', name: 'PhoneAuthDialog');
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        context.go('/'); // Navigate to home
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ OTP verification failed',
        name: 'PhoneAuthDialog',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() { 
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _resendOTP() async {
    setState(() { _error = null; });
    await _sendOTP();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: kPrimaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otpSent ? 'Verify OTP' : 'Phone Sign In',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _otpSent 
                              ? 'Enter the 6-digit code sent to $_phoneNumber'
                              : 'Enter your mobile number to receive OTP',
                          style: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              if (!_otpSent) ...[
                // Phone number input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country code dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          borderRadius: BorderRadius.circular(8),
                          items: _countryCodes.map((country) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Text(
                                '${country['flag']} ${country['code']}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            );
                          }).toList(),
                          onChanged: _isLoading ? null : (value) {
                            setState(() { _countryCode = value!; });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone number field
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '1234567890',
                          prefixIcon: Icon(Icons.phone_rounded),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        autofocus: true,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (value.length < 10) {
                            return 'Phone number must be at least 10 digits';
                          }
                          return null;
                        },
                        onFieldSubmitted: !_isLoading ? (_) => _sendOTP() : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: kPrimaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We\'ll send you a 6-digit verification code via SMS',
                          style: TextStyle(
                            fontSize: 12,
                            color: kTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // OTP input
                TextFormField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'OTP Code',
                    hintText: '123456',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 8,
                  ),
                  enabled: !_isLoading,
                  onFieldSubmitted: !_isLoading ? (_) => _verifyOTP() : null,
                ),
                
                const SizedBox(height: 16),
                
                // Resend OTP link
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _resendOTP,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Resend OTP'),
                    style: TextButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                    ),
                  ),
                ),
              ],

              // Error display
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kErrorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kErrorColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: kErrorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: kErrorColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (_otpSent)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _otpSent = false;
                            _otpController.clear();
                            _error = null;
                          });
                        },
                        child: const Text('Change Number'),
                      ),
                    ),
                  if (_otpSent) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading 
                          ? null 
                          : (_otpSent ? _verifyOTP : _sendOTP),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _otpSent ? 'Verify & Sign In' : 'Send OTP',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

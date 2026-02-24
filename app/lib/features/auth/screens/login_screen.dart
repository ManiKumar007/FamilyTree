import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../config/theme.dart';
// import '../widgets/phone_auth_dialog.dart'; // Disabled - enable when phone auth is configured
import 'dart:developer' as developer;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSendingReset = false;
  String? _error;
  String? _resetMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      developer.log('❌ Form validation failed', name: 'LoginScreen');
      return;
    }

    final email = _emailController.text.trim();
    developer.log('🔐 Sign in attempt started', name: 'LoginScreen', error: {'email': email});
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      developer.log('📞 Calling authService.signInWithPassword', name: 'LoginScreen');
      
      final response = await authService.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      
      developer.log('✅ Sign in successful', name: 'LoginScreen', error: {
        'user_id': response.user?.id,
        'email': response.user?.email,
        'session': response.session != null ? 'present' : 'null'
      });
      
      if (mounted) {
        developer.log('🚀 Navigating to home screen', name: 'LoginScreen');
        context.go('/');
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Sign in failed',
        name: 'LoginScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() { _error = _formatErrorMessage(e.toString()); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    developer.log('🔐 Google sign in attempt started', name: 'LoginScreen');
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      developer.log('📞 Calling authService.signInWithGoogle', name: 'LoginScreen');
      
      await authService.signInWithGoogle();
      
      developer.log('✅ Google sign in initiated', name: 'LoginScreen');
      
      // Navigation will be handled by auth state listener
    } catch (e, stackTrace) {
      developer.log(
        '❌ Google sign in failed',
        name: 'LoginScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithFacebook() async {
    developer.log('🔐 Facebook sign in attempt started', name: 'LoginScreen');
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      developer.log('📞 Calling authService.signInWithFacebook', name: 'LoginScreen');
      
      await authService.signInWithFacebook();
      
      developer.log('✅ Facebook sign in initiated', name: 'LoginScreen');
      
      // Navigation will be handled by auth state listener
    } catch (e, stackTrace) {
      developer.log(
        '❌ Facebook sign in failed',
        name: 'LoginScreen',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithPhone() async {
    developer.log('📱 Phone sign in initiated', name: 'LoginScreen');
    
    await showDialog(
      context: context,
      builder: (context) => const PhoneAuthDialog(),
    );
  }

  void _goToSignUp() {
    context.push('/signup');
  }

  String _formatErrorMessage(String error) {
    final cleanError = error.replaceAll('Exception: ', '');
    if (cleanError.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (cleanError.contains('Email not confirmed')) {
      return 'Please verify your email address before signing in.';
    } else if (cleanError.toLowerCase().contains('network') || cleanError.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (cleanError.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return cleanError;
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: kPrimaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text('Reset Password'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(color: kTextSecondary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: resetEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'you@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isSendingReset,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    if (_resetMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _resetMessage!.startsWith('Error')
                              ? kErrorColor.withValues(alpha: 0.08)
                              : Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _resetMessage!.startsWith('Error')
                                ? kErrorColor.withValues(alpha: 0.2)
                                : Colors.green.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _resetMessage!.startsWith('Error')
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: _resetMessage!.startsWith('Error')
                                  ? kErrorColor
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _resetMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _resetMessage!.startsWith('Error')
                                      ? kErrorColor
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() { _resetMessage = null; });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSendingReset
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {});
                          setState(() { _isSendingReset = true; _resetMessage = null; });
                          try {
                            final authService = ref.read(authServiceProvider);
                            await authService.resetPasswordForEmail(
                              resetEmailController.text.trim(),
                            );
                            setState(() {
                              _resetMessage = 'Password reset link sent! Check your email.';
                            });
                            setDialogState(() {});
                          } catch (e) {
                            setState(() {
                              _resetMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
                            });
                            setDialogState(() {});
                          } finally {
                            setState(() { _isSendingReset = false; });
                          }
                        },
                  child: _isSendingReset
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/landing'),
          tooltip: 'Back to Home',
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Left decorative panel (desktop only)
            if (isDesktop)
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.hero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_tree_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Connect with\nyour roots',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Build, explore, and share your family tree\nwith the people who matter most.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Right form panel
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo / App name
                          if (!isDesktop) ...[
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.account_tree_rounded,
                                size: 36,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to MyFamilyTree',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: kTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Email input
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              hintText: 'you@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofocus: true,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!value.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password input
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: !_isLoading ? (_) => _signIn() : null,
                            enabled: !_isLoading,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Forgot Password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign in button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),

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
                          // Divider with "OR"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Google Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: BorderSide(color: Colors.grey.shade300),
                                backgroundColor: Colors.white,
                              ),
                              icon: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: kTextPrimary,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Facebook Sign-In Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithFacebook,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: BorderSide(color: Colors.grey.shade300),
                                backgroundColor: const Color(0xFF1877F2),
                              ),
                              icon: const Icon(
                                Icons.facebook_rounded,
                                size: 24,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Continue with Facebook',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Phone auth disabled (no SMS provider configured)
                          // To enable: Set up Twilio in Supabase and uncomment below
                          // const SizedBox(height: 16),
                          // SizedBox(
                          //   width: double.infinity,
                          //   child: OutlinedButton.icon(
                          //     onPressed: _isLoading ? null : _signInWithPhone,
                          //     style: OutlinedButton.styleFrom(
                          //       minimumSize: const Size(double.infinity, 50),
                          //       side: BorderSide(color: Colors.grey.shade300),
                          //       backgroundColor: Colors.white,
                          //     ),
                          //     icon: const Icon(
                          //       Icons.phone_android_rounded,
                          //       size: 22,
                          //       color: kPrimaryColor,
                          //     ),
                          //     label: const Text(
                          //       'Continue with Phone',
                          //       style: TextStyle(
                          //         fontSize: 15,
                          //         fontWeight: FontWeight.w600,
                          //         color: kTextPrimary,
                          //       ),
                          //     ),
                          //   ),
                          // ),

                          const SizedBox(height: 24),
                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: kTextSecondary),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _goToSignUp,
                                child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

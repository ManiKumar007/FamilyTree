import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth_service.dart';
import '../../../config/theme.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isSending = false;
  String? _message;
  bool _isError = false;

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationEmail(email: widget.email);
      if (mounted) {
        setState(() {
          _message = 'Verification email sent! Please check your inbox.';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e.toString().replaceAll('Exception: ', '');
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() { _isSending = false; });
    }
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
          onPressed: () => context.go('/login'),
          tooltip: 'Back to Sign In',
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
                            Icons.group_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Start your\nfamily story',
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
                          'Create your family tree and connect\ngenerations together.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Right panel
            Expanded(
              flex: isDesktop ? 4 : 1,
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Email icon
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.mark_email_unread_outlined,
                              size: 56,
                              color: kPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Title
                          const Text(
                            'Verify your email',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            'We\'ve sent a verification link to',
                            style: TextStyle(fontSize: 15, color: kTextSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.email,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Click the link in the email to verify your account before signing in.',
                            style: TextStyle(fontSize: 14, color: kTextSecondary, height: 1.5),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 32),

                          // Info box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.blue.shade600),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Check your spam/junk folder if you don\'t see the email in your inbox within a few minutes.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Feedback message
                          if (_message != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _isError
                                    ? kErrorColor.withValues(alpha: 0.08)
                                    : kSuccessColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isError
                                      ? kErrorColor.withValues(alpha: 0.2)
                                      : kSuccessColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                                    size: 18,
                                    color: _isError ? kErrorColor : kSuccessColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _message!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _isError ? kErrorColor : kSuccessColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Resend button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isSending ? null : _resendEmail,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                side: BorderSide(color: kPrimaryColor, width: 1.5),
                              ),
                              icon: _isSending
                                  ? SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: kPrimaryColor,
                                      ),
                                    )
                                  : Icon(Icons.refresh_rounded, color: kPrimaryColor),
                              label: Text(
                                _isSending ? 'Sending...' : 'Resend verification email',
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Go to login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/login'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Go to Sign In',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Wrong email? ',
                                style: TextStyle(color: kTextSecondary),
                              ),
                              TextButton(
                                onPressed: () => context.go('/signup'),
                                child: const Text(
                                  'Sign up again',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
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

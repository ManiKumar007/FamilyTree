import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;
import 'package:myfamilytree/config/constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Is user logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get the authentication provider(s) used by the current user
  /// Returns list of provider names (e.g., ['email'], ['google'], ['email', 'google'])
  List<String> get authProviders {
    final user = currentUser;
    if (user == null) return [];
    
    // Get all identity providers from user identities
    return user.identities?.map((identity) => identity.provider ?? 'unknown').toList() ?? [];
  }

  /// Check if user signed up with email/password
  bool get hasEmailPasswordAuth {
    return authProviders.contains('email');
  }

  /// Check if user signed up with social login (OAuth)
  bool get hasSocialAuth {
    final providers = authProviders;
    return providers.any((p) => p == 'google' || p == 'facebook' || p == 'apple' || p == 'github');
  }

  /// Check if user can update password (only email/password users can)
  bool get canUpdatePassword {
    return hasEmailPasswordAuth;
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    // Normalize email to lowercase to prevent case-mismatch issues (especially on iOS)
    final normalizedEmail = email.trim().toLowerCase();
    developer.log('Attempting sign up', name: 'AuthService');
    
    try {
      // Validate inputs
      if (normalizedEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
        throw Exception('Please enter a valid email address');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }
      if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        throw Exception('Password must contain uppercase, lowercase, and a number');
      }

      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: metadata,
      );
      
      developer.log('✅ Supabase sign up successful', name: 'AuthService', error: {
        'user_id': response.user?.id,
        'email': response.user?.email,
        'has_session': response.session != null,
      });
      
      return response;
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Sign up failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during sign up',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Normalize email to lowercase to prevent case-mismatch issues (especially on iOS)
    final normalizedEmail = email.trim().toLowerCase();
    developer.log('🔑 Attempting password sign in', name: 'AuthService', error: {'email': normalizedEmail});
    
    try {
      // Validate inputs
      if (normalizedEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
        throw Exception('Please enter a valid email address');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters');
      }

      developer.log('Calling Supabase auth.signInWithPassword', name: 'AuthService');
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      
      developer.log('✅ Supabase sign in successful', name: 'AuthService', error: {
        'user_id': response.user?.id,
        'email': response.user?.email,
        'has_session': response.session != null,
        'access_token_length': response.session?.accessToken.length ?? 0,
      });
      
      return response;
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Authentication failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during sign in',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    developer.log('🔐 Attempting Google OAuth sign in', name: 'AuthService');
    
    try {
      developer.log('📡 Calling Supabase auth.signInWithOAuth', name: 'AuthService');
      // Set explicit redirect URL to frontend
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? AppConfig.appUrl : null,
      );
      
      developer.log('✅ Google OAuth initiated', name: 'AuthService', error: {
        'success': response,
      });
      
      return response;
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Google sign in failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during Google sign in',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with Facebook OAuth
  Future<bool> signInWithFacebook() async {
    developer.log('🔐 Attempting Facebook OAuth sign in', name: 'AuthService');
    
    try {
      developer.log('📡 Calling Supabase auth.signInWithOAuth', name: 'AuthService');
      // Set explicit redirect URL to frontend
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? AppConfig.appUrl : null,
      );
      
      developer.log('✅ Facebook OAuth initiated', name: 'AuthService', error: {
        'success': response,
      });
      
      return response;
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Facebook sign in failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during Facebook sign in',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign in with phone number (sends OTP)
  Future<void> signInWithPhone(String phoneNumber) async {
    developer.log('📱 Attempting phone sign in', name: 'AuthService', error: {'phone': phoneNumber});
    
    try {
      // Validate phone number format
      if (phoneNumber.isEmpty) {
        developer.log('❌ Phone number is empty', name: 'AuthService');
        throw Exception('Phone number cannot be empty');
      }
      if (!phoneNumber.startsWith('+')) {
        developer.log('❌ Invalid phone number format', name: 'AuthService', error: {'phone': phoneNumber});
        throw Exception('Phone number must include country code (e.g., +1234567890)');
      }
      if (phoneNumber.length < 10) {
        developer.log('❌ Phone number too short', name: 'AuthService');
        throw Exception('Please enter a valid phone number');
      }

      developer.log('📡 Calling Supabase auth.signInWithOtp', name: 'AuthService');
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
      
      developer.log('✅ OTP sent successfully', name: 'AuthService', error: {'phone': phoneNumber});
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Failed to send OTP: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during phone sign in',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Verify OTP code for phone authentication
  Future<AuthResponse> verifyPhoneOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    developer.log('🔐 Verifying phone OTP', name: 'AuthService', error: {'phone': phoneNumber});
    
    try {
      // Validate inputs
      if (phoneNumber.isEmpty) {
        developer.log('❌ Phone number is empty', name: 'AuthService');
        throw Exception('Phone number cannot be empty');
      }
      if (otpCode.isEmpty) {
        developer.log('❌ OTP code is empty', name: 'AuthService');
        throw Exception('OTP code cannot be empty');
      }
      if (otpCode.length != 6) {
        developer.log('❌ Invalid OTP length', name: 'AuthService');
        throw Exception('OTP code must be 6 digits');
      }

      developer.log('📡 Calling Supabase auth.verifyOTP', name: 'AuthService');
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: otpCode,
        type: OtpType.sms,
      );
      
      developer.log('✅ Phone verification successful', name: 'AuthService', error: {
        'user_id': response.user?.id,
        'phone': response.user?.phone,
        'has_session': response.session != null,
      });
      
      return response;
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('OTP verification failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during OTP verification',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    developer.log('👋 Signing out', name: 'AuthService');
    await _supabase.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPasswordForEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    developer.log('🔑 Sending password reset email', name: 'AuthService', error: {'email': normalizedEmail});

    try {
      if (normalizedEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
        throw Exception('Please enter a valid email address');
      }

      // Set explicit redirect URL to password reset page
      await _supabase.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: kIsWeb ? '${AppConfig.appUrl}/#/reset-password' : null,
      );

      developer.log('✅ Password reset email sent', name: 'AuthService', error: {'email': email});
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException during password reset',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Password reset failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during password reset',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update password for currently logged-in user
  /// Note: Only works for users who signed up with email/password
  /// Users who signed up with social login (Google, Facebook) cannot update password
  Future<void> updatePassword(String newPassword) async {
    developer.log('🔑 Updating password', name: 'AuthService');

    try {
      // Check if user can update password (email/password auth only)
      if (!canUpdatePassword) {
        final providers = authProviders.join(', ');
        developer.log(
          '🚫 Cannot update password - user signed in via: $providers',
          name: 'AuthService',
        );
        throw Exception(
          'Cannot update password. You signed in with ${providers}. '
          'Password updates are only available for email/password accounts.'
        );
      }

      if (newPassword.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password');
      }

      developer.log('✅ Password updated successfully', name: 'AuthService');
    } on AuthException catch (e) {
      developer.log(
        '🚫 Supabase AuthException during password update',
        name: 'AuthService',
        error: {'message': e.message, 'statusCode': e.statusCode},
      );
      throw Exception('Password update failed: ${e.message}');
    } catch (e, stackTrace) {
      developer.log(
        '❌ Unexpected error during password update',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get access token for API calls
  String? get accessToken => currentSession?.accessToken;

  /// Refresh the current session to get a new token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshSession() async {
    try {
      developer.log('Refreshing session', name: 'AuthService');
      
      final response = await _supabase.auth.refreshSession();
      
      if (response.session != null) {
        developer.log('Session refreshed successfully', name: 'AuthService');
        return true;
      } else {
        developer.log('Session refresh returned null', name: 'AuthService');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error refreshing session',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - just return false to indicate failure
      return false;
    }
  }
}
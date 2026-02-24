import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;

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

  /// Sign up with email and password
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    developer.log('📝 Attempting sign up', name: 'AuthService', error: {'email': email, 'metadata': metadata});
    
    try {
      // Validate inputs
      if (email.isEmpty) {
        developer.log('❌ Email is empty', name: 'AuthService');
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        developer.log('❌ Password is empty', name: 'AuthService');
        throw Exception('Password cannot be empty');
      }
      if (!email.contains('@')) {
        developer.log('❌ Invalid email format', name: 'AuthService', error: {'email': email});
        throw Exception('Invalid email format');
      }
      if (password.length < 6) {
        developer.log('❌ Password too short', name: 'AuthService');
        throw Exception('Password must be at least 6 characters');
      }

      developer.log('📡 Calling Supabase auth.signUp', name: 'AuthService');
      final response = await _supabase.auth.signUp(
        email: email,
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
    developer.log('🔑 Attempting password sign in', name: 'AuthService', error: {'email': email});
    
    try {
      // Validate inputs
      if (email.isEmpty) {
        developer.log('❌ Email is empty', name: 'AuthService');
        throw Exception('Email cannot be empty');
      }
      if (password.isEmpty) {
        developer.log('❌ Password is empty', name: 'AuthService');
        throw Exception('Password cannot be empty');
      }
      if (!email.contains('@')) {
        developer.log('❌ Invalid email format', name: 'AuthService', error: {'email': email});
        throw Exception('Invalid email format');
      }
      if (password.length < 6) {
        developer.log('❌ Password too short', name: 'AuthService');
        throw Exception('Password must be at least 6 characters');
      }

      developer.log('📡 Calling Supabase auth.signInWithPassword', name: 'AuthService');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
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
        redirectTo: kIsWeb ? 'http://localhost:5500' : null,
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

  /// Sign out
  Future<void> signOut() async {
    developer.log('👋 Signing out', name: 'AuthService');
    await _supabase.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPasswordForEmail(String email) async {
    developer.log('🔑 Sending password reset email', name: 'AuthService', error: {'email': email});

    try {
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      // Set explicit redirect URL to password reset page
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? 'http://localhost:5500/#/reset-password' : null,
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
  Future<void> updatePassword(String newPassword) async {
    developer.log('🔑 Updating password', name: 'AuthService');

    try {
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
      developer.log('🔄 Refreshing session', name: 'AuthService');
      final oldToken = currentSession?.accessToken;
      print('Old token length: ${oldToken?.length ?? 0}');
      
      final response = await _supabase.auth.refreshSession();
      
      if (response.session != null) {
        final newToken = response.session!.accessToken;
        print('New token length: ${newToken.length}');
        print('Token changed: ${oldToken != newToken}');
        developer.log('✅ Session refreshed successfully', name: 'AuthService');
        return true;
      } else {
        developer.log('⚠️ Session refresh returned null', name: 'AuthService');
        print('❌ Session refresh failed: returned null session');
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error refreshing session',
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
      print('❌ Session refresh exception: $e');
      // Don't rethrow - just return false to indicate failure
      return false;
    }
  }
}